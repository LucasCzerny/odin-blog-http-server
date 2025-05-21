package server

import "core:log"
import "core:strings"

Request :: struct {
	uri:     string,
	headers: [Request_Header]string,
	content: string,
}

Request_Header :: enum {
	accept,
	accept_charset,
	accept_encoding,
	accept_language,
	authorization,
	cache_control,
	content_length,
	content_type,
	cookie,
	host,
	origin,
	referer,
	user_agent,
	connection,
	upgrade_insecure_requests,
}

parse_request :: proc(raw_request: ^string) -> (request: Request, ok: bool) {
	//                                       v empty line that separates content from the rest
	blocks := strings.split_n(raw_request^, "\r\n\r\n", 2)

	// first line is request line
	request_line := true

	for line in strings.split_iterator(&blocks[0], "\r\n") {
		if request_line {
			ok = parse_request_line(&request, line)
		} else {
			ok = parse_header(&request, line)
		}

		if !ok {
			return
		}

		request_line = false
	}

	request.content = blocks[1]

	return
}

parse_request_line :: proc(request: ^Request, line: string) -> bool {
	fields := strings.split(line, " ")

	if len(fields) != 3 {
		log.errorf("Received %d fields in the request line instead of 3", len(fields))
		return false
	}

	if fields[0] != "GET" {
		log.errorf("Received method %s in the request. Only GET is supported", fields[0])
		return false
	}

	request.uri = fields[1]

	if fields[2] != "HTTP/1.1" {
		log.errorf("Received version %s in the request. Only HTTP/1.1 is supported", fields[2])
		return false
	}

	return true
}

parse_header :: proc(request: ^Request, line: string) -> bool {
	fields := strings.split(line, ": ")

	if len(fields) != 2 {
		log.errorf(
			"Invalid header format in the request. Received %s fields instead of 2 in this line:\n\"%s\"",
			len(fields),
			line,
		)
		return false
	}

	name, content := fields[0], fields[1]

	switch (name) {
	case "Accept":
		request.headers[.accept] = content
	case "Accept-Charset":
		request.headers[.accept_charset] = content
	case "Accept-Encoding":
		request.headers[.accept_encoding] = content
	case "Accept-Language":
		request.headers[.accept_language] = content
	case "Authorization":
		request.headers[.authorization] = content
	case "Cache-Control":
		request.headers[.cache_control] = content
	case "Content-Length":
		request.headers[.content_length] = content
	case "Content-Type":
		request.headers[.content_type] = content
	case "Cookie":
		request.headers[.cookie] = content
	case "Host":
		request.headers[.host] = content
	case "Origin":
		request.headers[.origin] = content
	case "Referer":
		request.headers[.referer] = content
	case "User-Agent":
		request.headers[.user_agent] = content
	case "Connection":
		request.headers[.connection] = content
	case "Upgrade-Insecure-Requests":
		request.headers[.upgrade_insecure_requests] = content
	case:
		log.infof("The header %s is not supported and will be ignored", name)
	}

	return true
}
