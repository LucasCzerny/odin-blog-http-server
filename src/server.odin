package server

import "core:log"
import "core:mem"
import "core:net"

main :: proc() {
	when ODIN_DEBUG {
		context.logger = log.create_console_logger(
			.Warning,
			{.Level, .Terminal_Color, .Short_File_Path, .Line, .Procedure},
		)
	}

	when ODIN_DEBUG {
		tracking_allocator: mem.Tracking_Allocator
		mem.tracking_allocator_init(&tracking_allocator, context.allocator)
		context.allocator = mem.tracking_allocator(&tracking_allocator)

		defer {
			for _, entry in tracking_allocator.allocation_map {
				context.logger = {}
				log.warnf("%v leaked %d bytes", entry.location, entry.size)
			}

			for entry in tracking_allocator.bad_free_array {
				context.logger = {}
				log.warnf("%v bad free on %v", entry.location, entry.memory)
			}

			mem.tracking_allocator_destroy(&tracking_allocator)
		}
	}

	tcp_socket: net.TCP_Socket

	if any_socket, create_err := net.create_socket(.IP4, .TCP); create_err == nil {
		tcp_socket = any_socket.(net.TCP_Socket)
	} else {
		log.errorf("Failed to create the socket (err: %v)", create_err)
		return
	}

	net.set_option(tcp_socket, .Reuse_Address, true)

	listen_endpoint := net.Endpoint {
		address = net.IP4_Address{127, 0, 0, 1},
		port    = 8080,
	}

	net.bind(tcp_socket, listen_endpoint)

	listen_socket, listen_err := net.listen_tcp(listen_endpoint)
	if listen_err != nil {
		log.errorf("Failed to put the socket into the listening state (err: %v)", listen_err)
		return
	}

	buffer := make([]u8, 1024)

	context.allocator = context.temp_allocator

	for true {
		client_socket, client_endpoint, accept_err := net.accept_tcp(listen_socket)
		if accept_err != nil {
			log.errorf(
				"Failed to accept the tcp connection (err: %v)",
				typeid_of(type_of(accept_err)),
			)
			continue
		}

		log.infof("Connection on %v", client_endpoint)

		bytes_read, recv_err := net.recv_tcp(client_socket, buffer)

		if bytes_read == 0 {
			continue
		} else if recv_err != nil {
			log.errorf("Failed to receive tcp data (err: %v)", recv_err)
			continue
		}

		raw_request := string(buffer[:bytes_read])

		request, request_ok := parse_request(&raw_request)
		if !request_ok {
			log.error("^ Failed to parse the request, we have to sit this one out :(")
			continue
		}

		response := respond(request)

		raw_response, ok := format_response(response)
		if !ok {
			log.error("^ Failed to format the response, not going to respond :(")
			continue
		}

		net.send_tcp(client_socket, transmute([]u8)raw_response)

		net.close(client_socket)

		free_all(context.allocator)
	}
}
