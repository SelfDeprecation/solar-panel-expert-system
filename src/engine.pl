:- encoding(utf8).

:- module(engine, [
    classify/2,
    evaluate_target/4,
    semantic_conflict/2
]).

:- use_module(feature_schema).
:- use_module(knowledge_base).
:- use_module(library(lists)).

/* Чистый механизм вывода: состояние сеанса передаётся обычным списком Feature=Value. */

classify(Answers, Result) :-
    findall(Conflict, semantic_conflict(Answers, Conflict), SemanticConflicts0),
    sort(SemanticConflicts0, SemanticConflicts),
    target_rankings(Answers, subtype, Rankings),
    decide_status(SemanticConflicts, Rankings, Status, BestTarget),
    build_result(Status, BestTarget, Answers, Rankings, SemanticConflicts, Result), !.

evaluate_target(Answers, Kind, Target, Summary) :-
    findall(Weight-RuleId-Conditions-Explanation-State,
            ( production_rule(RuleId, Kind, Target, Weight, Conditions, Explanation),
              rule_state(Answers, Conditions, State)
            ),
            Rows),
    matched_rows(Rows, MatchedRows),
    findall(Weight, member(Weight-_-_-_-matched, MatchedRows), Weights),
    sum_list(Weights, Score),
    findall(Id, member(_-Id-_-_-matched, MatchedRows), AppliedRules),
    findall(Explanation, member(_-_-_-Explanation-matched, MatchedRows), Explanations),
    findall(Feature,
            ( member(_-_-Conditions-_-missing, Rows),
              member(Condition, Conditions),
              condition_feature(Condition, Feature),
              answer_value(Answers, Feature, unknown)
            ),
            Missing0),
    sort(Missing0, Missing),
    findall(conflict(Feature, Actual, Expected),
            ( member(_-_-Conditions-_-contradicted, Rows),
              member(Condition, Conditions),
              condition_conflict(Answers, Condition, Feature, Actual, Expected)
            ),
            RuleConflicts0),
    sort(RuleConflicts0, RuleConflicts),
    Summary = summary{
        target:Target,
        score:Score,
        applied_rules:AppliedRules,
        explanations:Explanations,
        missing_features:Missing,
        rule_conflicts:RuleConflicts
    }.

matched_rows([], []).
matched_rows([Row|Rows], [Row|Matched]) :-
    Row = _-_-_-_-matched, !,
    matched_rows(Rows, Matched).
matched_rows([_|Rows], Matched) :-
    matched_rows(Rows, Matched).

target_rankings(Answers, Kind, Rankings) :-
    setof(Target, Id^Weight^Conditions^Explanation^
          production_rule(Id, Kind, Target, Weight, Conditions, Explanation), Targets),
    findall(Score-Target-Summary,
            ( member(Target, Targets),
              evaluate_target(Answers, Kind, Target, Summary),
              Score = Summary.score
            ),
            Unsorted),
    predsort(compare_ranking, Unsorted, Rankings).

compare_ranking(Order, ScoreA-TargetA-_, ScoreB-TargetB-_) :-
    ( ScoreA > ScoreB -> Order = '<'
    ; ScoreA < ScoreB -> Order = '>'
    ; compare(Order, TargetA, TargetB)
    ).

decide_status([_|_], Rankings, contradictory, Best) :-
    best_target(Rankings, Best), !.
decide_status([], [BestScore-Best-_, SecondScore-_-_|_], Status, Best) :-
    !,
    ( BestScore < 12 -> Status = insufficient
    ; SecondScore >= 12,
      BestScore - SecondScore < 4 -> Status = contradictory
    ; Status = classified
    ).
decide_status([], [BestScore-Best-_], Status, Best) :-
    ( BestScore >= 12 -> Status = classified ; Status = insufficient ).

best_target([_-Best-_|_], Best).

build_result(classified, Target, Answers, Rankings, SemanticConflicts, Result) :-
    once(member(_-Target-Summary, Rankings)),
    subtype_family(Target, Family),
    evaluate_target(Answers, family, Family, FamilySummary),
    append(FamilySummary.applied_rules, Summary.applied_rules, AppliedRules),
    append(FamilySummary.explanations, Summary.explanations, Explanations),
    append(FamilySummary.missing_features, Summary.missing_features, Missing0),
    sort(Missing0, Missing),
    append(FamilySummary.rule_conflicts, Summary.rule_conflicts, RuleConflicts0),
    sort(RuleConflicts0, RuleConflicts),
    Result = result{
        status:classified,
        family:Family,
        subtype:Target,
        score:Summary.score,
        family_score:FamilySummary.score,
        applied_rules:AppliedRules,
        explanations:Explanations,
        missing_features:Missing,
        contradicting_features:RuleConflicts,
        semantic_conflicts:SemanticConflicts,
        entered_answers:Answers,
        scores:Rankings
    }.
build_result(Status, Target, Answers, Rankings, SemanticConflicts, Result) :-
    Status \= classified,
    once(member(_-Target-Summary, Rankings)),
    Result = result{
        status:Status,
        family:unknown,
        subtype:unknown,
        best_candidate:Target,
        score:Summary.score,
        applied_rules:Summary.applied_rules,
        explanations:Summary.explanations,
        missing_features:Summary.missing_features,
        contradicting_features:Summary.rule_conflicts,
        semantic_conflicts:SemanticConflicts,
        entered_answers:Answers,
        scores:Rankings
    }.

rule_state(Answers, Conditions, State) :-
    maplist(condition_state(Answers), Conditions, States),
    ( memberchk(contradicted, States) -> State = contradicted
    ; memberchk(missing, States) -> State = missing
    ; State = matched
    ).

condition_state(Answers, eq(Feature, Expected), State) :-
    answer_value(Answers, Feature, Actual),
    ( Actual == unknown -> State = missing
    ; Actual == Expected -> State = matched
    ; State = contradicted
    ).
condition_state(Answers, one_of(Feature, ExpectedValues), State) :-
    answer_value(Answers, Feature, Actual),
    ( Actual == unknown -> State = missing
    ; memberchk(Actual, ExpectedValues) -> State = matched
    ; State = contradicted
    ).
condition_state(Answers, threshold(ThresholdId), State) :-
    threshold(ThresholdId, Feature, Operator, Limit, _),
    answer_value(Answers, Feature, Actual),
    ( Actual == unknown -> State = missing
    ; number(Actual), compare_number(Operator, Actual, Limit) -> State = matched
    ; State = contradicted
    ).

compare_number(ge, Actual, Limit) :- Actual >= Limit.
compare_number(le, Actual, Limit) :- Actual =< Limit.
compare_number(gt, Actual, Limit) :- Actual > Limit.
compare_number(lt, Actual, Limit) :- Actual < Limit.

answer_value(Answers, Feature, Value) :-
    ( memberchk(Feature=Found, Answers) -> Value = Found ; Value = unknown ).

condition_feature(eq(Feature, _), Feature).
condition_feature(one_of(Feature, _), Feature).
condition_feature(threshold(Id), Feature) :- threshold(Id, Feature, _, _, _).

condition_conflict(Answers, eq(Feature, Expected), Feature, Actual, Expected) :-
    answer_value(Answers, Feature, Actual),
    Actual \== unknown,
    Actual \== Expected.
condition_conflict(Answers, one_of(Feature, Expected), Feature, Actual, Expected) :-
    answer_value(Answers, Feature, Actual),
    Actual \== unknown,
    \+ memberchk(Actual, Expected).
condition_conflict(Answers, threshold(Id), Feature, Actual, threshold(Id, Operator, Limit)) :-
    threshold(Id, Feature, Operator, Limit, _),
    answer_value(Answers, Feature, Actual),
    Actual \== unknown,
    \+ compare_number(Operator, Actual, Limit).

semantic_conflict(Answers, conflict(material, crystalline_silicon, structure, thin_film)) :-
    memberchk(material=crystalline_silicon, Answers),
    memberchk(structure=thin_film, Answers).
semantic_conflict(Answers, conflict(material, Material, structure, crystalline)) :-
    memberchk(material=Material, Answers),
    memberchk(Material, [amorphous_silicon, cadmium_telluride, cigs]),
    memberchk(structure=crystalline, Answers).
semantic_conflict(Answers, conflict(technology_label, Label, material, Material)) :-
    memberchk(technology_label=Label, Answers),
    memberchk(material=Material, Answers),
    Label \== unknown,
    Label \== absent,
    \+ compatible_material_label(Material, Label).
semantic_conflict(Answers, conflict(nominal_power, Pmax, calculated_power, Calculated)) :-
    memberchk(nominal_power=Pmax, Answers), number(Pmax),
    memberchk(max_power_voltage=Vmp, Answers), number(Vmp),
    memberchk(max_power_current=Imp, Answers), number(Imp),
    Calculated is Vmp * Imp,
    Difference is abs(Pmax - Calculated),
    Difference > max(10, Pmax * 0.35).

compatible_material_label(crystalline_silicon, mono).
compatible_material_label(crystalline_silicon, poly).
compatible_material_label(amorphous_silicon, asi).
compatible_material_label(cadmium_telluride, cdte).
compatible_material_label(cigs, cigs).
