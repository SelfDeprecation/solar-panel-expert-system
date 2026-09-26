:- encoding(utf8).

:- module(reference_cases, [reference_case/4]).

/* 25 эталонных карточек: по пять вариантов для каждого подтипа. */

reference_case(Name, Family, Subtype, Answers) :-
    case_variant(Name, Subtype, PowerDelta, EfficiencyDelta),
    subtype_family_expected(Subtype, Family),
    base_case(Subtype, Base),
    adjust_numeric(Base, PowerDelta, EfficiencyDelta, Answers).

case_variant(mono_1, monocrystalline, 0, 0.0).
case_variant(mono_2, monocrystalline, 5, 0.3).
case_variant(mono_3, monocrystalline, -5, -0.2).
case_variant(mono_4, monocrystalline, 10, 0.5).
case_variant(mono_5, monocrystalline, -10, -0.4).
case_variant(poly_1, polycrystalline, 0, 0.0).
case_variant(poly_2, polycrystalline, 5, 0.2).
case_variant(poly_3, polycrystalline, -5, -0.2).
case_variant(poly_4, polycrystalline, 10, 0.4).
case_variant(poly_5, polycrystalline, -10, -0.3).
case_variant(asi_1, amorphous_silicon, 0, 0.0).
case_variant(asi_2, amorphous_silicon, 2, 0.2).
case_variant(asi_3, amorphous_silicon, -2, -0.2).
case_variant(asi_4, amorphous_silicon, 4, 0.4).
case_variant(asi_5, amorphous_silicon, -4, -0.4).
case_variant(cdte_1, cadmium_telluride, 0, 0.0).
case_variant(cdte_2, cadmium_telluride, 5, 0.2).
case_variant(cdte_3, cadmium_telluride, -5, -0.2).
case_variant(cdte_4, cadmium_telluride, 10, 0.4).
case_variant(cdte_5, cadmium_telluride, -10, -0.3).
case_variant(cigs_1, cigs, 0, 0.0).
case_variant(cigs_2, cigs, 5, 0.3).
case_variant(cigs_3, cigs, -5, -0.2).
case_variant(cigs_4, cigs, 10, 0.5).
case_variant(cigs_5, cigs, -10, -0.4).

subtype_family_expected(monocrystalline, crystalline_silicon_family).
subtype_family_expected(polycrystalline, crystalline_silicon_family).
subtype_family_expected(amorphous_silicon, thin_film_family).
subtype_family_expected(cadmium_telluride, thin_film_family).
subtype_family_expected(cigs, thin_film_family).

base_case(monocrystalline, [
    material=crystalline_silicon, structure=crystalline, cell_shape=pseudo_square,
    surface_color=black, surface_uniformity=uniform, crystal_boundaries=absent,
    busbar_geometry=fine_dense, rigidity=rigid, substrate=glass, transparency=opaque,
    cell_count=120, nominal_power=410, open_circuit_voltage=45.2,
    short_circuit_current=11.4, max_power_voltage=37.8, max_power_current=10.85,
    efficiency=21.0, power_temp_coefficient=(-0.30), module_length=1722,
    module_width=1134, mass=21.0, technology_label=mono
]).
base_case(polycrystalline, [
    material=crystalline_silicon, structure=crystalline, cell_shape=square,
    surface_color=blue, surface_uniformity=mottled, crystal_boundaries=visible,
    busbar_geometry=visible_regular, rigidity=rigid, substrate=glass, transparency=opaque,
    cell_count=72, nominal_power=330, open_circuit_voltage=45.5,
    short_circuit_current=9.4, max_power_voltage=37.2, max_power_current=8.87,
    efficiency=17.0, power_temp_coefficient=(-0.39), module_length=1956,
    module_width=992, mass=22.0, technology_label=poly
]).
base_case(amorphous_silicon, [
    material=amorphous_silicon, structure=thin_film, cell_shape=no_visible_cells,
    surface_color=dark_brown, surface_uniformity=uniform, crystal_boundaries=absent,
    busbar_geometry=absent, rigidity=flexible, substrate=polymer, transparency=semitransparent,
    cell_count=30, nominal_power=100, open_circuit_voltage=80.0,
    short_circuit_current=1.6, max_power_voltage=62.5, max_power_current=1.60,
    efficiency=11.0, power_temp_coefficient=(-0.20), module_length=1400,
    module_width=1000, mass=5.0, technology_label=asi
]).
base_case(cadmium_telluride, [
    material=cadmium_telluride, structure=thin_film, cell_shape=no_visible_cells,
    surface_color=dark_brown, surface_uniformity=uniform, crystal_boundaries=absent,
    busbar_geometry=barely_visible, rigidity=rigid, substrate=glass, transparency=opaque,
    cell_count=116, nominal_power=450, open_circuit_voltage=190.0,
    short_circuit_current=3.0, max_power_voltage=160.0, max_power_current=2.81,
    efficiency=18.0, power_temp_coefficient=(-0.25), module_length=1200,
    module_width=600, mass=32.0, technology_label=cdte
]).
base_case(cigs, [
    material=cigs, structure=thin_film, cell_shape=no_visible_cells,
    surface_color=gray_green, surface_uniformity=uniform, crystal_boundaries=absent,
    busbar_geometry=barely_visible, rigidity=flexible, substrate=metal_foil, transparency=opaque,
    cell_count=90, nominal_power=180, open_circuit_voltage=75.0,
    short_circuit_current=3.1, max_power_voltage=60.0, max_power_current=3.0,
    efficiency=17.0, power_temp_coefficient=(-0.30), module_length=1800,
    module_width=500, mass=7.0, technology_label=cigs
]).

adjust_numeric(Base, PowerDelta, EfficiencyDelta, Adjusted) :-
    maplist(adjust_value(PowerDelta, EfficiencyDelta), Base, Adjusted).

adjust_value(PowerDelta, _, nominal_power=Value, nominal_power=Adjusted) :-
    !, Adjusted is Value + PowerDelta.
adjust_value(_, EfficiencyDelta, efficiency=Value, efficiency=Adjusted) :-
    !, Adjusted is Value + EfficiencyDelta.
adjust_value(_, _, Pair, Pair).
