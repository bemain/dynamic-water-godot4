extends MeshInstance2D

## The number of grid points in the simulation
@export var grid_points: Vector2i = Vector2i(512, 512): set = set_grid_points
## The propagation speed of the waves
@export var wave_speed = 0.065
## Amplitude of newly created waves in the simulation
@export var initial_amplitude = 0.5
@export var mesh_amplitude = 1.0 # amplitude of waves in the mesh shader
## Texture for the land mass
@export var land_texture : Texture = ImageTexture.create_from_image(Image.create(1, 1, false, Image.FORMAT_RGB8))

## Viewport that contains the simulation texture
@onready var simulation_viewport: SubViewport = $SimulationViewport
## Viewport that contains the collision texture
@onready var collision_viewport: SubViewport = $CollisionViewport
## Material that contains the simulation shader
@onready var simulation_material: ShaderMaterial = simulation_viewport.get_node("ColorRect").material
@onready var surface_material: ShaderMaterial = material


# Size of the water body in both dimensions
var water_size = 50.0

# Current height map of the surface as raw byte array
var surface_data = PackedByteArray()

## Viewport textures that contain the rendered height and collision maps
var simulation_texture: ViewportTexture
var collision_texture: ViewportTexture


func _ready():
	# When the window changes size, resize collision_viewport
	get_tree().get_root().size_changed.connect(resize_window)
	
	simulation_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	
	var root_viewport = get_tree().root.get_viewport()
	root_viewport.canvas_cull_mask = 1
	collision_viewport.world_2d = root_viewport.world_2d
	
	# Set simulation and collision textures from viewports
	simulation_texture = simulation_viewport.get_texture()
	collision_texture = collision_viewport.get_texture()
	
	resize_window()
	set_grid_points(grid_points)
	
	# Set uniforms of mesh shader
	surface_material.set_shader_parameter("simulation_texture", simulation_texture)
	surface_material.set_shader_parameter("collision_texture", collision_texture)
	surface_material.set_shader_parameter("amplitude", mesh_amplitude)


func _initialize():
	# Create an empty texture
	var img = Image.create(grid_points.x, grid_points.y, false, Image.FORMAT_RGB8)
	var tex = ImageTexture.create_from_image(img)

	# Initialize the simulation with the empty texture
	simulation_material.set_shader_parameter("z_tex", tex)
	simulation_material.set_shader_parameter("old_z_tex", tex.duplicate(true))
	simulation_material.set_shader_parameter("collision_texture", tex.duplicate(true))
	simulation_material.set_shader_parameter("old_collision_texture", tex.duplicate(true))
	simulation_material.set_shader_parameter("land_texture", land_texture)

	# Set simulation parameters
	var delta = 1.0 / ProjectSettings.get_setting("physics/common/physics_ticks_per_second")
	var a = wave_speed*wave_speed * delta*delta * grid_points.x * grid_points.y
	if a > 0.5:
		push_warning("a > 0.5; Unstable simulation.")
	simulation_material.set_shader_parameter("a", a)
	simulation_material.set_shader_parameter("amplitude", initial_amplitude)


func _physics_process(_delta):
	_update()
	surface_data = simulation_texture.get_image().get_data()

var lock = false
func _update():
	if not lock:
		lock = true
		update_collision_texture()
		update_height_map()
		
		# Render one frame of the simulation viewport to update the simulation
		simulation_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE

		# Wait until the frame is rendered, then unlock
		await get_tree().process_frame
		lock = false

func set_grid_points(p_grid_points):
	grid_points = p_grid_points
	if is_inside_tree():
		# Set viewport sizes to simulation grid size
		simulation_viewport.size = grid_points
		simulation_viewport.get_node("ColorRect").get_rect().size = Vector2(grid_points)
		simulation_material.set_shader_parameter("grid_points", grid_points)
		_initialize()


## Update the collision texture
func update_collision_texture():
	var img = collision_texture.get_image() # Get the currently rendered map
	img.resize(grid_points.x, grid_points.y) # Scale to the correct grid size
	# Set current map as old map
	var old_collision_texture = simulation_material.get_shader_parameter("collision_texture")
	simulation_material.get_shader_parameter("old_collision_texture").set_image(old_collision_texture.get_image())
	simulation_material.get_shader_parameter("collision_texture").set_image(img) # Set the current collision map from current render

## Update the simulation texture
func update_height_map():
	var img = simulation_texture.get_image() # Get currently rendered map
	# Set current map as old map
	var old_height_map = simulation_material.get_shader_parameter("z_tex")
	simulation_material.get_shader_parameter("old_z_tex").set_image(old_height_map.get_image())
	simulation_material.get_shader_parameter("z_tex").set_image(img) # Set the current height map from current render


func resize_window():
	if is_inside_tree():
		collision_viewport.size = DisplayServer.window_get_size()


# Get the height at a position
func get_height(global_pos):
	var local_pos = to_local(global_pos)

	# Get pixel position
	var y = int((local_pos.x + water_size / 2.0) / water_size * (grid_points.y))
	var x =	int((local_pos.z + water_size / 2.0) / water_size * (grid_points.x))

	# Just return a very low height when not inside texture
	if x > grid_points.x - 1 or y > grid_points.y - 1 or x < 0 or y < 0:
		return -99999.9

	# Get height from surface data (in RGB8 format)
	# This is faster than locking the image and using get_pixel()
	var height = mesh_amplitude * (surface_data[3*(x*(grid_points.x) + y)] - surface_data[3*(x*(grid_points.x) + y) + 1]) / 255.0
	return height
