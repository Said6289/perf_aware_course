package gen

import "core:fmt"
import "core:os"
import "core:strings"
import "core:math"
import "core:math/rand"

rand_float64_inclusive :: proc(r: ^rand.Rand, lo: f64, hi: f64) -> f64 {
	n := f64(rand.int63_max((1 << 52) + 1, r)) / (1 << 52);
	return lo + n * (hi - lo);
}

main :: proc() {
	r := rand.create(69);
	N :: 10000000;

	b := strings.builder_make();

	fmt.sbprintf(&b, "{{\"pairs\":[\n");
	for i in 0..<N {
		x0 := rand_float64_inclusive(&r, -180, 180);
		y0 := rand_float64_inclusive(&r, -90, 90);
		x1 := rand_float64_inclusive(&r, -180, 180);
		y1 := rand_float64_inclusive(&r, -90, 90);
		fmt.sbprintf(&b, "{{\"x0\": %v, \"y0\": %v, \"x1\": %v, \"y1\": %v}}", x0, y0, x1, y1);
		if i < N - 1 {
			fmt.sbprintf(&b, ",\n");
		} else {
			fmt.sbprintf(&b, "\n");
		}
	}
	fmt.sbprintf(&b, "]}}\n");

	os.write_entire_file("../data_10000000_flex.json", b.buf[:]);
}
