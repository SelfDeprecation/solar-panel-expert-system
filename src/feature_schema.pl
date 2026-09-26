:- encoding(utf8).

:- module(feature_schema, [
    feature/3,
    feature_label/2,
    value_label/2,
    valid_answer/2,
    all_feature_ids/1
]).

/*
   Схема входных данных экспертной системы.
   unknown является допустимым ответом: пользователь может не знать признак.
*/

feature(material, enum([crystalline_silicon, amorphous_silicon, cadmium_telluride, cigs, unknown]),
        'Материал фотоактивного слоя').
feature(structure, enum([crystalline, thin_film, unknown]),
        'Структура фотоактивного слоя').
feature(cell_shape, enum([square, pseudo_square, irregular, no_visible_cells, unknown]),
        'Форма ячеек').
feature(surface_color, enum([black, blue, dark_brown, gray_green, unknown]),
        'Преобладающий цвет поверхности').
feature(surface_uniformity, enum([uniform, mottled, unknown]),
        'Однородность поверхности').
feature(crystal_boundaries, enum([visible, absent, unknown]),
        'Видимые границы кристаллов').
feature(busbar_geometry, enum([visible_regular, fine_dense, barely_visible, absent, unknown]),
        'Геометрия токосъёмных линий').
feature(rigidity, enum([rigid, flexible, unknown]),
        'Жёсткость модуля').
feature(substrate, enum([glass, polymer, metal_foil, unknown]),
        'Тип подложки').
feature(transparency, enum([opaque, semitransparent, unknown]),
        'Прозрачность модуля').
feature(cell_count, number(1, 300, 'шт.'), 'Число ячеек').
feature(nominal_power, number(1, 1500, 'Вт'), 'Номинальная мощность').
feature(open_circuit_voltage, number(1, 2000, 'В'), 'Напряжение холостого хода').
feature(short_circuit_current, number(0.01, 100, 'А'), 'Ток короткого замыкания').
feature(max_power_voltage, number(0.1, 1800, 'В'), 'Напряжение в точке максимальной мощности').
feature(max_power_current, number(0.01, 100, 'А'), 'Ток в точке максимальной мощности').
feature(efficiency, number(1, 35, '%'), 'Коэффициент полезного действия').
feature(power_temp_coefficient, number(-1.5, 0, '%/°C'), 'Температурный коэффициент мощности').
feature(module_length, number(50, 5000, 'мм'), 'Длина модуля').
feature(module_width, number(50, 3000, 'мм'), 'Ширина модуля').
feature(mass, number(0.01, 100, 'кг'), 'Масса модуля').
feature(technology_label, enum([mono, poly, asi, cdte, cigs, absent, unknown]),
        'Обозначение технологии в маркировке или паспорте').

feature_label(Feature, Label) :-
    feature(Feature, _, Label).

valid_answer(Feature, unknown) :-
    feature(Feature, _, _), !.
valid_answer(Feature, Value) :-
    feature(Feature, enum(Values), _),
    memberchk(Value, Values), !.
valid_answer(Feature, Value) :-
    feature(Feature, number(Min, Max, _), _),
    number(Value),
    Value >= Min,
    Value =< Max, !.

all_feature_ids(Ids) :-
    findall(Id, feature(Id, _, _), Ids).

value_label(crystalline_silicon, 'кристаллический кремний').
value_label(amorphous_silicon, 'аморфный кремний').
value_label(cadmium_telluride, 'теллурид кадмия').
value_label(cigs, 'CIGS').
value_label(crystalline, 'кристаллическая').
value_label(thin_film, 'тонкоплёночная').
value_label(square, 'квадратные').
value_label(pseudo_square, 'псевдоквадратные со скруглёнными углами').
value_label(irregular, 'неправильной формы').
value_label(no_visible_cells, 'отдельные ячейки не различимы').
value_label(black, 'чёрный').
value_label(blue, 'синий').
value_label(dark_brown, 'тёмно-коричневый').
value_label(gray_green, 'серо-зелёный').
value_label(uniform, 'однородная').
value_label(mottled, 'неоднородная или пятнистая').
value_label(visible, 'видны').
value_label(absent, 'отсутствуют').
value_label(visible_regular, 'хорошо видимые регулярные линии').
value_label(fine_dense, 'тонкая плотная сетка').
value_label(barely_visible, 'слабо различимые линии').
value_label(rigid, 'жёсткий').
value_label(flexible, 'гибкий').
value_label(glass, 'стекло').
value_label(polymer, 'полимер').
value_label(metal_foil, 'металлическая фольга').
value_label(opaque, 'непрозрачный').
value_label(semitransparent, 'полупрозрачный').
value_label(mono, 'mono / monocrystalline').
value_label(poly, 'poly / multicrystalline').
value_label(asi, 'a-Si').
value_label(cdte, 'CdTe').
value_label(absent, 'обозначение отсутствует').
value_label(unknown, 'неизвестно').
