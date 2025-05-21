package server

import "core:log"
import "core:strings"

respond :: proc(request: Request) -> Response {
	// Invalid request
	if request.uri == "" {
		return respond_with_error(.internal_server_error)
	}

	if request.uri == "/" {
		return respond_with_homepage()
	} else {
		path := strings.trim_left(request.uri, "/")
		return respond_with_resource(path)
	}
}

@(private = "file")
respond_with_homepage :: proc() -> Response {
	content, ok := fetch_homepage_html()
	if !ok {
		log.errorf(
			"^ Failed to fetch the error html, responding with .internal_server_error instead",
		)

		return respond_with_error(.internal_server_error)
	}

	return Response{status_code = .ok, content_type = .text_html, content = transmute([]u8)content}
}

@(private = "file")
respond_with_error :: proc(error_code: Status_Code) -> Response {
	content, ok := fetch_error_html(error_code)
	if !ok {
		log.errorf(
			"^ Failed to fetch the error html, responding with .internal_server_error instead of %v",
			error_code,
		)

		return Response{status_code = .internal_server_error}
	}

	return Response {
		status_code = error_code,
		content_type = .text_html,
		content = transmute([]u8)content,
	}
}

@(private = "file")
respond_with_resource :: proc(path: string) -> Response {
	content, type, ok := fetch_resource(path)
	if !ok {
		log.errorf("^ Failed to fetch the resource \"%s\", responding with .not_found", path)
		return respond_with_error(.not_found)
	}

	return Response{status_code = .ok, content_type = type, content = content}
}

