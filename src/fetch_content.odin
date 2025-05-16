package server

import "core:log"
import "core:os"
import "core:strings"

fetch_file :: proc(filepath: string) -> ([]u8, bool) {
	content, err := os.read_entire_file_from_filename_or_err(filepath)
	if err != nil {
		log.errorf("Could not read %s (%v)", filepath, err)
		return {}, false
	}

	return content, true
}

fetch_homepage_html :: proc() -> (string, bool) {
	html_path :: "content/html/index.html"

	base_html, ok := fetch_file(html_path)
	if !ok {
		log.errorf("^ Failed to open \"%s\"", html_path)
		return "", false
	}

	// TODO: actually get the previews
	posts_html := "peepee popo"

	html, replace_ok := strings.replace(string(base_html), "<!-- posts -->", posts_html, 1)
	if !replace_ok {
		log.errorf("Failed to insert the post previews into index.html")
		return "", false
	}

	delete(base_html)

	return html, true
}

fetch_error_html :: proc() -> (string, bool) {
	error_path :: "content/html/error.html"

	html, ok := fetch_file(error_path)
	if !ok {
		log.errorf("^ Failed to open \"%s\"", error_path)
		return "", false
	}

	return string(html), true
}

fetch_resource :: proc(path: string, extension: string) -> ([]u8, bool) {
	content_path :: "content/"

	folder: string
	type: Content_Type

	switch (extension) {
	case "html":
		folder = "posts"
		type = .text_html
	case "css":
		folder = "styles"
		type = .text_css
	case "png":
		folder = "images"
		type = .image_png
	case "jpg", "jpeg":
		folder = "images"
		type = .image_jpeg
	case "ico":
		folder = "images"
		type = .image_x_icon
	}

	path_split := strings.split(path, "/", allocator = context.temp_allocator)
	if len(path_split) != 2 {
		log.errorf(
			"Invalid path \"%s\", it has to be exactly one subfolder deep (like <folder>/<name>.<ext>)",
			path,
		)
		return {}, false
	}

	if path_split[0] != folder {
		log.errorf("Trying to access a \"%s\" file from the \"%s\" folder", extension, folder)
		return {}, false
	}

	return fetch_file(path)
}

