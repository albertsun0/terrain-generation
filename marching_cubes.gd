@tool
extends MeshInstance3D
const c = preload("res://scripts/mc_constants.gd")
var constants = c.new()

var triTable = constants.triTable
var cornerIndexAFromEdge = constants.cornerIndexAFromEdge
var cornerIndexBFromEdge = constants.cornerIndexBFromEdge

@export var update = false
@export var size_X = 50
@export var size_Y = 10
@export var size_Z = 50
@export var heightLimit = 6.0
@export var noiseScale = 5.0
@export var THRESHOLD = 0.2

var noise = FastNoiseLite.new()
var noise2 = FastNoiseLite.new()


# Called when the node enters the scene tree for the first time.
func _ready():
	gen_mesh()

func get_noise(x:float, y:float, z:float):
	if y <= 1:
		return 1
	return noise.get_noise_3d(x * noiseScale, y * noiseScale, z * noiseScale) * (heightLimit/ y)

func atovec3(x):
	return Vector3(x[0], x[1], x[2])
	
func interpolate(a,b):
	return (atovec3(a) + atovec3(b))/2

func gen_mesh():
	var amesh = ArrayMesh.new()
	var vertices = PackedVector3Array([])
	var indices = PackedInt32Array([])
	
	# loop through entire area
	for i in range(size_X):
		for j in range(size_Y):
			for k in range(size_Z):
				# generate cube corners for positions
				if i > 0 and j > 0 and k > 0:
					var corners = [
						[i - 1, j-1, k],
						[i, j-1, k],
						[i, j-1, k-1],
						[i - 1, j-1, k-1],
						[i - 1, j, k],
						[i, j, k],
						[i, j, k-1],
						[i - 1, j, k-1],
					]
					
					# generate cube index as bitmask of corners to keep
					var cubeindex = 0
					for corner_index in range(corners.size()):
						var c = corners[corner_index]
						if get_noise(c[0], c[1], c[2]) > THRESHOLD:
							cubeindex |= 1 << corner_index
					
					# lookup and create mesh vertices/triangles
					var triangulation = triTable[cubeindex]
					
					for index in range(0, triangulation.size(), 3):
						if triangulation[index] == -1:
							break
							
						var a0 = cornerIndexAFromEdge[triangulation[index]]
						var b0 = cornerIndexBFromEdge[triangulation[index]]
						var a1 = cornerIndexAFromEdge[triangulation[index + 1]]
						var b1 = cornerIndexBFromEdge[triangulation[index + 1]]
						var a2 = cornerIndexAFromEdge[triangulation[index + 2]]
						var b2 = cornerIndexBFromEdge[triangulation[index + 2]]
						
						var offset = vertices.size()
						vertices.append(interpolate(corners[a0],corners[b0]))
						vertices.append(interpolate(corners[a1],corners[b1]))
						vertices.append(interpolate(corners[a2],corners[b2]))
						indices.append_array([offset, offset + 1, offset + 2])

	var array = []
	array.resize(Mesh.ARRAY_MAX)
	array[Mesh.ARRAY_VERTEX] = vertices
	array[Mesh.ARRAY_INDEX] = indices
	amesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, array)
	mesh = amesh
	
	var surftool = SurfaceTool.new()
	surftool.set_smooth_group(-1)
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
