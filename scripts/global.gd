class_name Global

static var g_fractal: FractalData
static var g_active_material: FractalMaterial

static var mandelbulb_data: Mandelbulb = Mandelbulb.new()
static var sierpinski_data: SierpinskiTetrahedron = SierpinskiTetrahedron.new()
static var g_data_arr: Array[FractalData] = [mandelbulb_data, sierpinski_data]
