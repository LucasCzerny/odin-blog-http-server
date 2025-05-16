package server

import "core:log"
import "core:os"
import "core:strings"

respond :: proc(request: Request) -> Response {
	// Invalid request
	if request.uri == "" {
		return respond_with_error(.internal_server_error)
	}

	path := strings.trim_left(request.uri, "/")

	if request.uri == "/" {
		content, ok := fetch_homepage_html()
		if !ok {
			log.error(
				"^ Failed to fetch the homepage html, responding with .internal_server_error instead",
			)

			return respond_with_error(.internal_server_error)
		}

		return respond_with_html(content)
	}

	return respond_with_error(.not_found)
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

