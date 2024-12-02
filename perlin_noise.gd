@tool
extends MeshInstance3D

@export var update = false
@export var size = 4
var noise = FastNoiseLite.new()
# Called when the node enters the scene tree for the first time.
func _ready():
	gen_mesh() # Replace with function body.

func get_noise(x:float, y:float):
	return noise.get_noise_2d(x * 20,y * 20) * 2
	
func gen_mesh():
	var amesh = ArrayMesh.new()
	var vertices = PackedVector3Array([])
	var indices = PackedInt32Array([])
	var N = size
	
	# loop through N x N area
	for i in range(N):
		for j in range(N):
			# add current vertex at height noise
			vertices.append(Vector3(i,get_noise(i,j),j))
			# stich vertices together
			if i > 0 and j > 0:
				var current = N * i + j
				indices.append_array([
					current - 1 - N, current, current - N 
					])
				indices.append_array([
					current - 1 - N, current - 1, current
					])
	var array = []
	array.resize(Mesh.ARRAY_MAX)
	array[Mesh.ARRAY_VERTEX] = vertices
	array[Mesh.ARRAY_INDEX] = indices
	amesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, array)
	mesh = amesh
	
	var surftool = SurfaceTool.new()
	# generate normals
	surftool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(vertices.size()):
		surftool.add_vertex(vertices[i])
	for i in indices:
		surftool.add_index(i)
	surftool.generate_normals()
	amesh = surftool.commit()
	
	mesh = amesh

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if update:
		gen_mesh()
		update = false
