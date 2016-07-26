json.array! @plant_density_abaci do |plant_density_abacus|
  json.call(plant_density_abacus, :id, :germination_percentage, :sampling_length_unit, :seeding_density_unit, :variety_name)
  json.items plant_density_abacus.items, :seeding_density_value, :plants_count
end
