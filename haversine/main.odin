package main

import "core:fmt"
import "core:os"
import "core:time"
import "core:strconv"
import "core:math"
import "core:unicode/utf8"
import "core:encoding/json"

haversine :: proc(x0, y0, x1, y1, r: f32) -> f32 {
	dy := (y1 - y0) * math.RAD_PER_DEG;
	dx := (x1 - x0) * math.RAD_PER_DEG;
	y0 := y0 * math.RAD_PER_DEG;
	y1 := y1 * math.RAD_PER_DEG;

	sin_half_dy := math.sin(0.5 * dy);
	sin_half_dx := math.sin(0.5 * dx);

	root_term := sin_half_dy * sin_half_dy;
	root_term += sin_half_dx * sin_half_dx * math.cos(y0) * math.cos(y1);

	return 2 * r * math.asin(math.sqrt(root_term));
}

skip_space :: proc(at: ^[]byte) {
	is_space :: proc "contextless" (r:  byte) -> bool {
		switch r {
		case ' ', '\t', '\n', '\v', '\f', '\r':
			return true;
		}
		return false;
	}

	for len(at^) > 0 {
		if !is_space(at[0]) do break;
		at^ = at[1:];
	}
}

expect_string :: proc(at: ^[]byte, str: string) -> bool {
	skip_space(at);
	if len(at) < len(str) do return false;
	result := string(at[:len(str)]) == str;
	if result do at^ = at[len(str):];
	return result;
}

parse_prelude :: proc(at: ^[]byte) -> bool {
	expect_string(at, "{") or_return;
	expect_string(at, "\"pairs\"") or_return;
	expect_string(at, ":") or_return;
	expect_string(at, "[") or_return;
	return true;
}

Pair :: struct {
	x0, y0, x1, y1: f32,
	end: bool,
}

expect_float :: proc(at: ^[]byte) -> (f: f32, ok: bool) {
	skip_space(at);
	offset := 0;
	for {
		if len(at) - offset <= 0 {
			offset += 1;
			break;
		}
		if at[offset] == ',' do break;
		if at[offset] == '}' do break;
		offset += 1;
	}
	f, ok = strconv.parse_f32(string(at[:offset]));
	if !ok do return;
	at^ = at[offset:];
	return;
}

parse_pair :: proc(at: ^[]byte) -> (pair: Pair, ok: bool) {
	expect_string(at, "{") or_return;
	expect_string(at, "\"x0\"") or_return;
	expect_string(at, ":") or_return;
	x0 := expect_float(at) or_return;
	expect_string(at, ",") or_return;

	expect_string(at, "\"y0\"") or_return;
	expect_string(at, ":") or_return;
	y0 := expect_float(at) or_return;
	expect_string(at, ",") or_return;

	expect_string(at, "\"x1\"") or_return;
	expect_string(at, ":") or_return;
	x1 := expect_float(at) or_return;
	expect_string(at, ",") or_return;

	expect_string(at, "\"y1\"") or_return;
	expect_string(at, ":") or_return;
	y1 := expect_float(at) or_return;

	expect_string(at, "}") or_return;
	end := !expect_string(at, ",");

	pair = Pair{x0=x0, y0=y0, x1=x1, y1=y1, end=end};
	ok = true;

	return;
}

main :: proc() {
	data, data_read := os.read_entire_file("data_10000000_flex.json");
	if !data_read {
		fmt.printf("Could not read input file.\n");
		return;
	}
	defer delete(data);

	start_time := time.tick_now();

	EARTH_RADIUS_KM :: 6371;

	sum := f32(0);
	count := 0;

	at := data[:];

	if !parse_prelude(&at) {
		fmt.printf("Could not parse prelude.\n");
		return;
	}

	for {
		pair, ok := parse_pair(&at);
		if !ok {
			fmt.printf("Could not parse a pair of coordinates.\n");
			return;
		};
		if pair.end do break;
		sum += haversine(pair.x0, pair.y0, pair.x1, pair.y1, EARTH_RADIUS_KM);
		count += 1;
	}
	average := sum / f32(count);

	end_time := time.tick_now();

	total_seconds := time.duration_seconds(time.tick_diff(start_time, end_time));

	fmt.printf("Result: %v\n", average);
	fmt.printf("Total = %v seconds\n", total_seconds);
	fmt.printf("Throughput = %v haversines/second\n", f64(count) / total_seconds);
}
