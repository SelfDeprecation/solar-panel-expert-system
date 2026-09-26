:- encoding(utf8).

:- module(knowledge_base, [
    production_rule/6,
    threshold/5,
    subtype_family/2,
    target_label/2,
    production_rule_count/1
]).

/*
   Пороговые значения вынесены из правил в отдельную группу фактов.
   Источники являются справочными; перед сдачей проекта значения следует
   сопоставить с паспортами выбранных эталонных модулей.

   DOE Solar Photovoltaic Cell Basics:
   https://www.energy.gov/eere/solar/solar-photovoltaic-cell-basics
   DOE PV Cells 101:
   https://www.energy.gov/eere/solar/articles/pv-cells-101-primer-solar-photovoltaic-cell
*/

threshold(high_efficiency, efficiency, ge, 19.0, 'DOE Solar Photovoltaic Cell Basics').
threshold(medium_efficiency, efficiency, ge, 15.0, 'DOE Solar Photovoltaic Cell Basics').
threshold(low_efficiency, efficiency, le, 15.0, 'DOE PV Cells 101').
threshold(good_temperature_coefficient, power_temp_coefficient, ge, -0.36,
          'Типовые паспортные данные кристаллических модулей').
threshold(thin_film_temperature_coefficient, power_temp_coefficient, ge, -0.30,
          'Типовые паспортные данные тонкоплёночных модулей').
threshold(conventional_cell_count_min, cell_count, ge, 54,
          'Типовые паспортные данные серийных модулей').

subtype_family(monocrystalline, crystalline_silicon_family).
subtype_family(polycrystalline, crystalline_silicon_family).
subtype_family(amorphous_silicon, thin_film_family).
subtype_family(cadmium_telluride, thin_film_family).
subtype_family(cigs, thin_film_family).

target_label(crystalline_silicon_family, 'кристаллический кремний').
target_label(thin_film_family, 'тонкоплёночная технология').
target_label(monocrystalline, 'монокристаллический кремний').
target_label(polycrystalline, 'поликристаллический кремний').
target_label(amorphous_silicon, 'аморфный кремний a-Si').
target_label(cadmium_telluride, 'теллурид кадмия CdTe').
target_label(cigs, 'диселенид меди, индия и галлия CIGS').

/*
   production_rule(Номер, Уровень, Заключение, Вес, Условия, Пояснение).
   Факты, пороги и служебные предикаты не входят в число продукционных правил.
*/

% Правила R001-R010: семейство технологии.
production_rule(r001, family, crystalline_silicon_family, 5, [eq(material, crystalline_silicon)],
                'Фотоактивный слой выполнен из кристаллического кремния').
production_rule(r002, family, crystalline_silicon_family, 4, [eq(structure, crystalline)],
                'Указана кристаллическая структура').
production_rule(r003, family, crystalline_silicon_family, 2, [one_of(cell_shape, [square, pseudo_square, irregular])],
                'В модуле различимы отдельные кристаллические ячейки').
production_rule(r004, family, crystalline_silicon_family, 2, [one_of(busbar_geometry, [visible_regular, fine_dense])],
                'На ячейках видна регулярная токосъёмная сетка').
production_rule(r005, family, crystalline_silicon_family, 1, [threshold(conventional_cell_count_min)],
                'Число ячеек характерно для серийного кристаллического модуля').
production_rule(r006, family, thin_film_family, 5, [one_of(material, [amorphous_silicon, cadmium_telluride, cigs])],
                'Материал относится к тонкоплёночным технологиям').
production_rule(r007, family, thin_film_family, 4, [eq(structure, thin_film)],
                'Указана тонкоплёночная структура').
production_rule(r008, family, thin_film_family, 2, [eq(cell_shape, no_visible_cells)],
                'Отдельные ячейки визуально не различимы').
production_rule(r009, family, thin_film_family, 2, [eq(surface_uniformity, uniform)],
                'Поверхность имеет характерный однородный вид').
production_rule(r010, family, thin_film_family, 1, [one_of(substrate, [polymer, metal_foil])],
                'Использована подложка, характерная для гибких тонких плёнок').

% Правила R011-R020: монокристаллический кремний.
production_rule(r011, subtype, monocrystalline, 5, [eq(technology_label, mono)],
                'В маркировке явно указан монокристаллический кремний').
production_rule(r012, subtype, monocrystalline, 2, [eq(material, crystalline_silicon)],
                'Материалом является кристаллический кремний').
production_rule(r013, subtype, monocrystalline, 3, [eq(cell_shape, pseudo_square)],
                'Ячейки имеют псевдоквадратную форму со скруглёнными углами').
production_rule(r014, subtype, monocrystalline, 2, [eq(surface_color, black)],
                'Поверхность преимущественно чёрная').
production_rule(r015, subtype, monocrystalline, 2, [eq(surface_uniformity, uniform)],
                'Цвет ячеек визуально однороден').
production_rule(r016, subtype, monocrystalline, 3, [eq(crystal_boundaries, absent)],
                'Внутри ячеек не видны границы отдельных кристаллов').
production_rule(r017, subtype, monocrystalline, 1, [eq(busbar_geometry, fine_dense)],
                'Присутствует тонкая плотная токосъёмная сетка').
production_rule(r018, subtype, monocrystalline, 2, [threshold(high_efficiency)],
                'КПД соответствует типичному высокому уровню монокристаллических модулей').
production_rule(r019, subtype, monocrystalline, 1, [threshold(good_temperature_coefficient)],
                'Температурный коэффициент соответствует современному кристаллическому модулю').
production_rule(r020, subtype, monocrystalline, 4,
                [eq(structure, crystalline), eq(surface_color, black), eq(crystal_boundaries, absent)],
                'Совокупность структуры, цвета и отсутствия границ указывает на монокристалл').

% Правила R021-R030: поликристаллический кремний.
production_rule(r021, subtype, polycrystalline, 5, [eq(technology_label, poly)],
                'В маркировке явно указан поликристаллический кремний').
production_rule(r022, subtype, polycrystalline, 2, [eq(material, crystalline_silicon)],
                'Материалом является кристаллический кремний').
production_rule(r023, subtype, polycrystalline, 3, [eq(cell_shape, square)],
                'Ячейки имеют квадратную форму').
production_rule(r024, subtype, polycrystalline, 3, [eq(surface_color, blue)],
                'Поверхность преимущественно синяя').
production_rule(r025, subtype, polycrystalline, 2, [eq(surface_uniformity, mottled)],
                'Поверхность неоднородна по оттенку').
production_rule(r026, subtype, polycrystalline, 4, [eq(crystal_boundaries, visible)],
                'Внутри ячеек видны границы кристаллов').
production_rule(r027, subtype, polycrystalline, 1, [eq(busbar_geometry, visible_regular)],
                'Токосъёмные линии хорошо различимы').
production_rule(r028, subtype, polycrystalline, 1, [threshold(medium_efficiency)],
                'КПД находится в рабочем диапазоне кристаллических модулей').
production_rule(r029, subtype, polycrystalline, 1, [eq(rigidity, rigid)],
                'Модуль имеет жёсткую конструкцию').
production_rule(r030, subtype, polycrystalline, 4,
                [eq(structure, crystalline), eq(surface_color, blue), eq(crystal_boundaries, visible)],
                'Совокупность структуры, синего цвета и границ указывает на поликристалл').

% Правила R031-R040: аморфный кремний a-Si.
production_rule(r031, subtype, amorphous_silicon, 5, [eq(technology_label, asi)],
                'В маркировке явно указана технология a-Si').
production_rule(r032, subtype, amorphous_silicon, 5, [eq(material, amorphous_silicon)],
                'Фотоактивный слой выполнен из аморфного кремния').
production_rule(r033, subtype, amorphous_silicon, 2, [eq(structure, thin_film)],
                'Модуль имеет тонкоплёночную структуру').
production_rule(r034, subtype, amorphous_silicon, 2, [eq(cell_shape, no_visible_cells)],
                'Отдельные ячейки не различимы').
production_rule(r035, subtype, amorphous_silicon, 2, [eq(surface_color, dark_brown)],
                'Поверхность имеет тёмно-коричневый оттенок').
production_rule(r036, subtype, amorphous_silicon, 1, [eq(surface_uniformity, uniform)],
                'Поверхность однородна').
production_rule(r037, subtype, amorphous_silicon, 1, [eq(crystal_boundaries, absent)],
                'Границы кристаллов отсутствуют').
production_rule(r038, subtype, amorphous_silicon, 2, [threshold(low_efficiency)],
                'КПД соответствует характерному диапазону a-Si').
production_rule(r039, subtype, amorphous_silicon, 2, [eq(substrate, polymer)],
                'Аморфный кремний нанесён на полимерную подложку').
production_rule(r040, subtype, amorphous_silicon, 4,
                [eq(structure, thin_film), eq(surface_color, dark_brown), eq(technology_label, asi)],
                'Совокупность тонкой плёнки, цвета и маркировки подтверждает a-Si').

% Правила R041-R050: теллурид кадмия CdTe.
production_rule(r041, subtype, cadmium_telluride, 5, [eq(technology_label, cdte)],
                'В маркировке явно указана технология CdTe').
production_rule(r042, subtype, cadmium_telluride, 5, [eq(material, cadmium_telluride)],
                'Фотоактивный слой выполнен из теллурида кадмия').
production_rule(r043, subtype, cadmium_telluride, 2, [eq(structure, thin_film)],
                'Модуль имеет тонкоплёночную структуру').
production_rule(r044, subtype, cadmium_telluride, 2, [eq(cell_shape, no_visible_cells)],
                'Отдельные ячейки визуально не различимы').
production_rule(r045, subtype, cadmium_telluride, 2, [eq(surface_color, dark_brown)],
                'Поверхность имеет тёмно-коричневый оттенок').
production_rule(r046, subtype, cadmium_telluride, 1, [eq(surface_uniformity, uniform)],
                'Покрытие однородно').
production_rule(r047, subtype, cadmium_telluride, 2, [eq(substrate, glass)],
                'Тонкоплёночный слой нанесён на стеклянную подложку').
production_rule(r048, subtype, cadmium_telluride, 1, [eq(rigidity, rigid)],
                'Модуль имеет жёсткую конструкцию').
production_rule(r049, subtype, cadmium_telluride, 1, [threshold(thin_film_temperature_coefficient)],
                'Температурный коэффициент характерен для тонкоплёночного модуля').
production_rule(r050, subtype, cadmium_telluride, 4,
                [eq(material, cadmium_telluride), eq(substrate, glass), eq(structure, thin_film)],
                'Совокупность материала, стекла и структуры подтверждает CdTe').

% Правила R051-R060: CIGS.
production_rule(r051, subtype, cigs, 5, [eq(technology_label, cigs)],
                'В маркировке явно указана технология CIGS').
production_rule(r052, subtype, cigs, 5, [eq(material, cigs)],
                'Фотоактивный слой выполнен из CIGS').
production_rule(r053, subtype, cigs, 2, [eq(structure, thin_film)],
                'Модуль имеет тонкоплёночную структуру').
production_rule(r054, subtype, cigs, 2, [eq(cell_shape, no_visible_cells)],
                'Отдельные ячейки визуально не различимы').
production_rule(r055, subtype, cigs, 2, [one_of(surface_color, [black, gray_green])],
                'Цвет поверхности характерен для CIGS').
production_rule(r056, subtype, cigs, 1, [eq(surface_uniformity, uniform)],
                'Покрытие однородно').
production_rule(r057, subtype, cigs, 3, [eq(rigidity, flexible)],
                'Модуль имеет гибкую конструкцию').
production_rule(r058, subtype, cigs, 3, [one_of(substrate, [polymer, metal_foil])],
                'Применена гибкая полимерная или металлическая подложка').
production_rule(r059, subtype, cigs, 1, [threshold(medium_efficiency)],
                'КПД соответствует современному CIGS-модулю').
production_rule(r060, subtype, cigs, 4,
                [eq(material, cigs), eq(structure, thin_film), one_of(substrate, [polymer, metal_foil])],
                'Совокупность материала, структуры и подложки подтверждает CIGS').

production_rule_count(Count) :-
    aggregate_all(count, production_rule(_, _, _, _, _, _), Count).

