extends RigidBody3D
class_name BouyantBody

@onready var probes = get_node("Probes")
@onready var collision_mesh = get_node("CollisionMesh")

@export var buoyancy = 5.0 : set = set_buoyancy, get = get_buoyancy
@export var created_waves_amplitude = 0.1 # Is multiplied with the linear velocity and controls height of created waves
@export var water_node_path : NodePath

func set_buoyancy(p_buoyancy):
	if is_inside_tree():
		for i in range(probes.get_child_count()):
			probes.get_child(i).buoyancy = p_buoyancy
	buoyancy = p_buoyancy

func get_buoyancy():
	return buoyancy

func _ready():
	collision_mesh.set_surface_override_material(0, collision_mesh.get_surface_override_material(0))
	for i in range(probes.get_child_count()):
		probes.get_child(i).water_node = get_node(water_node_path)
		probes.get_child(i).buoyancy = buoyancy

func _physics_process(delta):
	collision_mesh.get_surface_override_material(0).set_shader_parameter("speed", created_waves_amplitude * linear_velocity.length())
	for i in range(probes.get_child_count()):
		if probes.get_child(i).force > 0.0:
			apply_force(Vector3(0.0, probes.get_child(i).force, 0.0) / probes.get_child_count(), probes.get_child(i).global_transform.origin - global_transform.origin)
