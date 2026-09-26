:- encoding(utf8).

:- module(dialog, [start/0, run_session/0]).

:- use_module(feature_schema).
:- use_module(knowledge_base).
:- use_module(engine).
:- use_module(library(readutil)).

start :-
    print_banner,
    session_loop.

session_loop :-
    run_session,
    ask_next_action(Action),
    ( Action == again -> nl, session_loop ; writeln('Работа завершена.') ).

run_session :-
    all_feature_ids(Features),
    collect_answers(Features, Answers),
    nl,
    classify(Answers, Result),
    print_result(Result).

print_banner :-
    production_rule_count(Count),
    nl,
    writeln('Экспертная система классификации солнечных батарей'),
    format('В базе знаний: ~d продукционных правил.~n', [Count]),
    writeln('Отвечайте номером варианта. Для неизвестного числового значения введите ?.'),
    writeln('Результат носит справочный характер и не заменяет паспорт изделия,'),
    writeln('маркировку производителя, лабораторное исследование или заключение специалиста.'),
    nl.

collect_answers([], []).
collect_answers([Feature|Features], [Feature=Value|Answers]) :-
    feature(Feature, Type, Prompt),
    ask_feature(Type, Prompt, Value),
    collect_answers(Features, Answers).

ask_feature(enum(Values), Prompt, Value) :-
    repeat,
    nl,
    format('~w:~n', [Prompt]),
    print_options(Values, 1),
    write('> '), flush_output,
    read_line_to_string(user_input, Raw),
    ( Raw == end_of_file -> Value = unknown, !
    ; normalize_space(string(Clean), Raw),
      catch(number_string(Index, Clean), _, fail),
      integer(Index),
      nth1(Index, Values, Value) -> !
    ; writeln('Ошибка: введите номер одного из предложенных вариантов.'), fail
    ).
ask_feature(number(Min, Max, Unit), Prompt, Value) :-
    repeat,
    nl,
    format('~w (~w, диапазон ~w..~w; ? — неизвестно):~n> ', [Prompt, Unit, Min, Max]),
    flush_output,
    read_line_to_string(user_input, Raw),
    ( Raw == end_of_file -> Value = unknown, !
    ; parse_number_answer(Raw, Parsed),
      ( Parsed == unknown -> Value = unknown, !
      ; Parsed >= Min, Parsed =< Max -> Value = Parsed, !
      ; format('Ошибка: значение должно находиться в диапазоне ~w..~w.~n', [Min, Max]), fail
      )
    ; writeln('Ошибка: введите число или символ ?.'), fail
    ).

print_options([], _).
print_options([Value|Values], Index) :-
    value_label(Value, Label),
    format('  ~d — ~w~n', [Index, Label]),
    Next is Index + 1,
    print_options(Values, Next).

parse_number_answer(Raw, unknown) :-
    normalize_space(string(Clean), Raw),
    memberchk(Clean, ["?", "не знаю", "unknown", ""]), !.
parse_number_answer(Raw, Number) :-
    normalize_space(string(Clean0), Raw),
    split_string(Clean0, ",", "", Parts),
    atomic_list_concat(Parts, '.', Atom),
    atom_number(Atom, Number).

print_result(Result) :-
    Status = Result.status,
    print_status(Status, Result),
    print_entered_answers(Result.entered_answers),
    print_applied_rules(Result.applied_rules, Result.explanations),
    print_missing(Result.missing_features),
    print_rule_conflicts(Result.contradicting_features),
    print_semantic_conflicts(Result.semantic_conflicts),
    print_disclaimer.

print_status(classified, Result) :-
    target_label(Result.family, FamilyLabel),
    target_label(Result.subtype, SubtypeLabel),
    nl,
    writeln('ЗАКЛЮЧЕНИЕ'),
    format('Семейство: ~w.~n', [FamilyLabel]),
    format('Подтип: ~w.~n', [SubtypeLabel]),
    format('Оценка подтверждения: ~d.~n', [Result.score]).
print_status(insufficient, Result) :-
    target_label(Result.best_candidate, CandidateLabel),
    nl,
    writeln('ЗАКЛЮЧЕНИЕ: недостаточно данных.'),
    format('Наиболее близкий кандидат: ~w (оценка ~d), но порог уверенности не достигнут.~n',
           [CandidateLabel, Result.score]).
print_status(contradictory, Result) :-
    target_label(Result.best_candidate, CandidateLabel),
    nl,
    writeln('ЗАКЛЮЧЕНИЕ: противоречивые данные.'),
    format('Наиболее близкий кандидат: ~w (оценка ~d), подтип не выдан.~n',
           [CandidateLabel, Result.score]).

print_entered_answers(Answers) :-
    nl,
    writeln('Введённые признаки:'),
    forall(member(Feature=Value, Answers), print_answer(Feature, Value)).

print_answer(Feature, Value) :-
    feature_label(Feature, Label),
    ( atom(Value), value_label(Value, ValueLabel) -> Display = ValueLabel ; Display = Value ),
    format('  - ~w: ~w~n', [Label, Display]).

print_applied_rules([], []) :-
    writeln('Применённые правила: нет.').
print_applied_rules(Rules, Explanations) :-
    atomic_list_concat(Rules, ', ', Text),
    format('Применённые правила: ~w.~n', [Text]),
    writeln('Объяснение вывода:'),
    print_rule_explanations(Rules, Explanations).

print_rule_explanations([], []).
print_rule_explanations([Rule|Rules], [Explanation|Explanations]) :-
    format('  - ~w: ~w.~n', [Rule, Explanation]),
    print_rule_explanations(Rules, Explanations).

print_missing([]) :-
    writeln('Отсутствующие существенные признаки: нет.').
print_missing(Features) :-
    writeln('Отсутствующие существенные признаки:'),
    forall(member(Feature, Features),
           ( feature_label(Feature, Label), format('  - ~w~n', [Label]) )).

print_rule_conflicts([]) :-
    writeln('Признаки, противоречащие лучшему заключению: нет.').
print_rule_conflicts(Conflicts) :-
    writeln('Признаки, противоречащие лучшему заключению:'),
    forall(member(Conflict, Conflicts), print_rule_conflict(Conflict)).

print_rule_conflict(conflict(Feature, Actual, Expected)) :-
    feature_label(Feature, FeatureLabel),
    display_value(Actual, ActualLabel),
    display_expected(Expected, ExpectedLabel),
    format('  - ~w: введено «~w», ожидалось «~w»~n',
           [FeatureLabel, ActualLabel, ExpectedLabel]).

display_value(Value, Label) :-
    ( atom(Value), value_label(Value, KnownLabel) -> Label = KnownLabel ; Label = Value ).

display_expected(Values, Label) :-
    is_list(Values), !,
    maplist(display_value, Values, Labels),
    atomic_list_concat(Labels, ' или ', Label).
display_expected(threshold(_, Operator, Limit), Label) :-
    !,
    operator_label(Operator, OperatorLabel),
    format(string(Label), '~w ~w', [OperatorLabel, Limit]).
display_expected(Value, Label) :-
    display_value(Value, Label).

operator_label(ge, 'не менее').
operator_label(le, 'не более').
operator_label(gt, 'более').
operator_label(lt, 'менее').

print_semantic_conflicts([]) :-
    writeln('Явные противоречия: не обнаружены.').
print_semantic_conflicts(Conflicts) :-
    writeln('Обнаруженные противоречия:'),
    forall(member(Conflict, Conflicts), format('  - ~q~n', [Conflict])).

print_disclaimer :-
    nl,
    writeln('Результат носит справочный характер и не заменяет паспорт изделия,'),
    writeln('маркировку производителя, лабораторное исследование или заключение специалиста.').

ask_next_action(Action) :-
    repeat,
    nl,
    writeln('1 — начать новый сеанс; 0 — завершить программу.'),
    write('> '), flush_output,
    read_line_to_string(user_input, Raw),
    normalize_space(string(Clean), Raw),
    ( Clean == "1" -> Action = again, !
    ; Clean == "0" -> Action = stop, !
    ; Raw == end_of_file -> Action = stop, !
    ; writeln('Введите 1 или 0.'), fail
    ).
