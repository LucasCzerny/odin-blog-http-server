package server

import "core:fmt"
import "core:log"
import "core:time"

Response :: struct {
	status_code:  Status_Code,
	content_type: Content_Type,
	content:      string,
}

Status_Code :: enum {
	ok                    = 200,
	moved_permanently     = 301,
	found                 = 302,
	not_modified          = 304,
	bad_request           = 400,
	unauthorized          = 401,
	forbidden             = 403,
	not_found             = 404,
	method_not_allowed    = 405,
	internal_server_error = 500,
	not_implemented       = 501,
}

Content_Type :: enum {
	text_html,
	text_css,
}

DEFAULT_HEADER :: "Server: A custom server written in odin :D\r\nConnection: closed\r\nDate: %s\r\nCache-Control: no-store\r\nContent-Type: %s\r\nContent-Length: %d\r\n"

format_response :: proc(response: Response) -> (string, bool) {
	time_stamp, ok := current_time()
	if !ok {
		return "", false
	}

	r := response

	raw_response := fmt.aprintf(
		"%v %v %v\r\n" + DEFAULT_HEADER + "\r\n%s",
		"HTTP/1.1",
		cast(int)r.status_code,
		get_status_description(r.status_code),
		time_stamp,
		content_type_to_str(response.content_type),
		len(r.content),
		r.content,
	)

	return raw_response, true
}

@(private = "file")
current_time :: proc() -> (string, bool) {
	now := time.now()

	date, ok := time.time_to_datetime(now)
	if !ok {
		return "", false
	}

	month_str, ok2 := month_to_str(date.month)
	if !ok2 {
		return "", false
	}

	time_buffer: [time.MIN_HMS_LEN]u8

	return fmt.aprintf(
			"%s, %0d %s %d %s GMT",
			time.weekday(now),
			date.day,
			month_str,
			date.year,
			time.to_string_hms(now, time_buffer[:]),
		),
		true
}

@(private = "file")
month_to_str :: proc(month: i8) -> (string, bool) {
	switch month {
	case 1:
		return "Jan", true
	case 2:
		return "Feb", true
	case 3:
		return "Mar", true
	case 4:
		return "Apr", true
	case 5:
		return "May", true
	case 6:
		return "Jun", true
	case 7:
		return "Jul", true
	case 8:
		return "Aug", true
	case 9:
		return "Sep", true
	case 10:
		return "Oct", true
	case 11:
		return "Nov", true
	case 12:
		return "Dec", true
	}

	log.errorf(
		"Invalid month \"%d\" in the response struct. Value has to be between in [1, 12]",
		month,
	)
	return "", false
}

@(private = "file")
get_status_description :: proc(status_code: Status_Code) -> string {
	switch (status_code) {
	case .ok:
		return "OK"
	case .moved_permanently:
		return "Moved Permanently"
	case .found:
		return "Found"
	case .not_modified:
		return "Not Modified"
	case .bad_request:
		return "Bad Request"
	case .unauthorized:
		return "Unauthorized"
	case .forbidden:
		return "Forbidden"
	case .not_found:
		return "Not Found"
	case .method_not_allowed:
		return "Method Not Allowed"
	case .internal_server_error:
		return "Internal Server Error"
	case .not_implemented:
		return "Not Implemented"
	}

	return ""
}

content_type_to_str :: proc(type: Content_Type) -> string {
	switch (type) {
	case .text_html:
		return "text/html"
	case .text_css:
		return "text/css"
	}

	return ""
}

