class_name Global

static var g_fractal: FractalData
static var g_active_material: FractalMaterial

static var mandelbulb_a_data: MandelbulbA = MandelbulbA.new()
static var mandelbulb_b_data: MandelbulbB = MandelbulbB.new()
static var mandelbulb_c_data: MandelbulbC = MandelbulbC.new()
static var dual_quaternion_julia_data: QuaternionJuliaSet = QuaternionJuliaSet.new()
static var quaternion_julia_data: QuaternionJuliaSetBasic = QuaternionJuliaSetBasic.new()
static var menger_koleidoscope_data: MengerKoleidoscope = MengerKoleidoscope.new()
static var mandelbox_data: Mandelbox = Mandelbox.new()
static var sierpinski_data: SierpinskiTetrahedron = SierpinskiTetrahedron.new()
static var g_data_arr: Array[FractalData] = [mandelbulb_a_data, mandelbulb_b_data, 
mandelbulb_c_data, mandelbox_data, quaternion_julia_data, dual_quaternion_julia_data, sierpinski_data, 
menger_koleidoscope_data]
