extends CharacterBody2D
class_name CollidingObject

@export var collision_mesh_path: NodePath = ^"CollisionMesh"
@onready var collision_mesh: Node2D = get_node(collision_mesh_path)

## Is multiplied with the linear velocity and controls height of created waves
@export var created_waves_amplitude = 0.1

func _ready():
	collision_mesh.visibility_layer = 2

func _physics_process(delta):
	collision_mesh.material.set_shader_parameter("speed", created_waves_amplitude * delta * velocity.length())
