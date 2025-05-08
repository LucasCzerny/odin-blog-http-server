package server

import "core:log"
import "core:os"
import "core:strings"

respond :: proc(request: Request) -> Response {
	// Invalid request
	if request.uri == "" {
		return respond_with_error(.internal_server_error)
	}

	if request.uri == "/" {
		content, ok := fetch_homepage_html()
		if !ok {
			log.error(
				"^ Failed to fetch the homepage html, responding with .internal_server_error instead",
			)

			return respond_with_error(.internal_server_error)
		}

		insert := make(map[string]string)
		insert["<!-- posts -->"] = get_post_list_html()

		defer delete(insert)

		insert_template_values(&content, insert)
		defer free_all(context.temp_allocator)

		return respond_with_html(content)
	}

	extension := strings.split(request.uri, ".")[1]

	if extension == "html" {
		content, not_found, ok := fetch_post_html(request.uri)
		if !ok {
			error_code: Status_Code = not_found ? .not_found : .internal_server_error

			log.errorf(
				"^ Failed to fetch the page html for \"request.uri\", responding with %v instead",
				error_code,
			)

			return respond_with_error(error_code)
		}

		return respond_with_html(content)
	} else {
		// content, not_found, ok := fetch_static_content(request.uri, extension)
		// if !ok {
		// error_code: Status_Code = not_found ? .not_found : .internal_server_error

		// log.errorf(
		// "^ Failed to fetch the static content for \"request.uri\", responding with %v instead",
		// error_code,
		// )

		// return respond_with_error(error_code)
		// }
		// 
		// return respond_with_static_content(content)
	}

	return {}
}

@(private = "file")
respond_with_html :: proc(html: string) -> Response {
	return Response{status_code = .ok, content_type = .text_html, content = html}
}

@(private = "file")
respond_with_error :: proc(error_code: Status_Code) -> Response {
	content, ok := fetch_error_html("error.html", error_code)
	if !ok {
		log.errorf(
			"^ Failed to fetch the error html, responding with .internal_server_error instead of %v",
			error_code,
		)
	}

	return Response{status_code = error_code, content_type = .text_html, content = content}
}

@(private = "file") //                   content, not_found, ok
fetch_post_html :: proc(uri: string) -> (string, bool, bool) {
	context.allocator = context.temp_allocator
	defer free_all(context.allocator)

	search_for := strings.split(uri, "/")[1]

	posts_dir, err1 := os.open("content/posts")
	if err1 != nil {
		log.errorf("Could not open the posts directory (%v)", err1)
		return {}, false, false
	}

	file_infos, err2 := os.read_dir(posts_dir, 100)
	if err2 != nil {
		log.errorf("Could not read the files from the posts directory (%v)", err2)
		return {}, false, false
	}

	for info in file_infos {
		if info.name != search_for {
			continue
		}

		md_content, ok := fetch_file(info.fullpath)
		html_content := convert_md_to_html(md_content)

		return html_content, false, ok
	}

	log.warn("The requested post was not found")
	return {}, true, false
}

@(private = "file")
fetch_homepage_html :: proc() -> (string, bool) {
	homepage_html :: "content/html/index.html"
	return fetch_file(homepage_html)
}

@(private = "file")
fetch_error_html :: proc(uri: string, error_code: Status_Code) -> (string, bool) {
	error_html :: "content/html/error.html"
	return fetch_file(error_html)
}

@(private = "file")
fetch_file :: proc(filepath: string) -> (string, bool) {
	content, err := os.read_entire_file_from_filename_or_err(filepath)
	if err != nil {
		log.errorf("Could not read %s (%v)", filepath, err)
		return {}, false
	}

	return string(content), true
}

@(private = "file")
insert_template_values :: proc(html: ^string, insert: map[string]string) {
	temp_html := html^

	for replace_str, insert_str in insert {
		// ignoring was_allocation; they're all going to be freed by the free_all call
		temp_html, _ = strings.replace_all(
			temp_html,
			replace_str,
			insert_str,
			context.temp_allocator,
		)
	}

	html^ = strings.clone(temp_html)
	free_all(context.temp_allocator)
}

@(private = "file")
get_post_list_html :: proc() -> string {
	post_html :: "content/html/post-list-item.html"

	post_template, ok := fetch_file(post_html)
}

