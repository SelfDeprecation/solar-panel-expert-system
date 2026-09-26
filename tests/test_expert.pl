:- encoding(utf8).

:- begin_tests(expert_system).

:- use_module('../src/engine').
:- use_module('../src/knowledge_base').
:- use_module('../src/feature_schema').
:- use_module(reference_cases).

test(production_rule_count_is_60) :-
    production_rule_count(60).

test(all_reference_cards_are_classified,
     [forall(reference_case(Name, ExpectedFamily, ExpectedSubtype, Answers))]) :-
    classify(Answers, Result),
    assertion(Result.status == classified),
    assertion(Result.family == ExpectedFamily),
    assertion(Result.subtype == ExpectedSubtype),
    format('~w: ~w/~w~n', [Name, Result.family, Result.subtype]).

test(insufficient_data_does_not_produce_subtype) :-
    classify([surface_color=black], Result),
    assertion(Result.status == insufficient),
    assertion(Result.subtype == unknown).

test(contradictory_data_does_not_produce_subtype) :-
    Answers = [material=crystalline_silicon, structure=thin_film,
               technology_label=mono, surface_color=black],
    classify(Answers, Result),
    assertion(Result.status == contradictory),
    assertion(Result.subtype == unknown).

test(enum_validation_accepts_known_value) :-
    valid_answer(structure, thin_film).

test(enum_validation_rejects_unknown_atom, [fail]) :-
    valid_answer(structure, liquid_crystal).

test(number_validation_accepts_boundary) :-
    valid_answer(efficiency, 35).

test(number_validation_rejects_out_of_range, [fail]) :-
    valid_answer(efficiency, 50).

test(unknown_is_allowed_for_every_feature,
     [forall(feature(Feature, _, _))]) :-
    valid_answer(Feature, unknown).

test(consecutive_sessions_are_independent) :-
    reference_case(mono_1, _, monocrystalline, FirstAnswers),
    reference_case(cigs_1, _, cigs, SecondAnswers),
    classify(FirstAnswers, FirstResult),
    classify(SecondAnswers, SecondResult),
    assertion(FirstResult.subtype == monocrystalline),
    assertion(SecondResult.subtype == cigs).

:- end_tests(expert_system).

:- initialization(main, main).

main :-
    ( run_tests -> halt(0) ; halt(1) ).

