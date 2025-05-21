package server

import "core:log"
import "core:os"
import "core:strconv"
import "core:strings"

fetch_homepage_html :: proc() -> (string, bool) {
	html_path :: "content/html/index.html"

	html, ok := fetch_file(html_path)
	if !ok {
		log.errorf("^ Failed to open \"%s\"", html_path)
		return "", false
	}

	return wrap_html(string(html)), true
}

fetch_error_html :: proc(status_code: Status_Code) -> (string, bool) {
	error_path :: "content/html/error.html"

	base_html, fetch_ok := fetch_file(error_path)
	if !fetch_ok {
		log.errorf("^ Failed to open \"%s\"", error_path)
		return "", false
	}

	buf: [4]u8
	status_code_str := strconv.itoa(buf[:], cast(int)status_code)

	html, replace_ok := strings.replace(
		string(base_html),
		"<!-- status code -->",
		status_code_str,
		1,
	)
	if !replace_ok {
		log.errorf("Failed to insert the status code into error.html")
		return "", false
	}

	return wrap_html(html), true
}

fetch_resource :: proc(path: string) -> ([]u8, Content_Type, bool) {
	content_path :: "content/"

	folder: string
	type: Content_Type

	extension := strings.split_after(path, ".")[1]

	switch (extension) {
	case "html":
		folder = "posts"
		type = .text_html
	case "css":
		folder = "styles"
		type = .text_css
	case "js":
		folder = "scripts"
		type = .application_javascript
	case "png":
		folder = "images"
		type = .image_png
	case "jpg", "jpeg":
		folder = "images"
		type = .image_jpeg
	case "svg":
		folder = "images"
		type = .image_svg_xml
	}

	path_split := strings.split(path, "/")
	if len(path_split) != 2 {
		log.errorf(
			"Invalid path \"%s\", it has to be exactly one subfolder deep (like <folder>/<name>.<ext>)",
			path,
		)
		return {}, {}, false
	}

	if path_split[0] != folder {
		log.errorf("Trying to access a \"%s\" file from the \"%s\" folder", extension, folder)
		return {}, {}, false
	}

	full_path := strings.join({"content", path}, "/")

	content, ok := fetch_file(full_path)
	if !ok {
		log.errorf("^ Failed to open \"%s\"", full_path)
	}

	if type == .text_html {
		content = transmute([]u8)wrap_html(string(content))
	}

	return content, type, true
}

@(private = "file")
fetch_file :: proc(filepath: string) -> ([]u8, bool) {
	content, err := os.read_entire_file_from_filename_or_err(filepath)
	if err != nil {
		log.errorf("Could not read %s (%v)", filepath, err)
		return {}, false
	}

	return content, true
}

@(private = "file")
wrap_html :: proc(html: string) -> string {
	return strings.join({html_prefix(), html, html_suffix()}, "\n")
}

@(private = "file")
html_prefix :: proc() -> string {
	return "<!DOCTYPE html>\n<html lang=\"en-US\">\n" + #load("../content/html/head.html")
}

@(private = "file")
html_suffix :: proc() -> string {
	return "</html>"
}
