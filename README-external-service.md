# External services for Toit

A service is Toit's way to expose C functionality to Toit code. C components
register callbacks that are invoked when a Toit program calls a service. Similarly,
services can send notifications to Toit containers.

See the [echo](components/echo) component for an example of a simple service.

## Includes

C components that want to expose a service must include the `toit/toit.h` header file.

## Registration

Services must be registered before the Toit VM starts. This means that they are usually
added using a C function that is marked with `__attribute__((constructor))`, as
these functions are called before `main`. Note that linkers usually need to have the
`--whole-archive` flag for this to work.

Example:

``` c
/// @brief  Register an external service.
static void __attribute__((constructor)) init() {
  toit_msg_cbs_t cbs = TOIT_MSG_EMPTY_CBS();
  cbs.on_created = on_created;
  cbs.on_message = on_message;
  cbs.on_rpc_request = on_rpc_request;
  cbs.on_removed = on_removed;
  toit_msg_add_handler("toitlang.org/demo", NULL, cbs);
}
```

The second argument to `toit_msg_add_handler` is user-data that is passed to the
callbacks when they are invoked. In our case we just used `NULL`, but often one
provides an object that is used to store state that is needed by the callbacks.

Callbacks that are not used can be left unset.

### ESP-IDF cmake

Services, like other components, should be registered using `idf_component_register`.
However, because Toit components use the constructor-attribute they require the
`WHOLE_ARCHIVE` flag:

Example:

``` cmake
idf_component_register(
  REQUIRES toit
  SRCS ...
  WHOLE_ARCHIVE
)
```

This call can be done in a `CMakeLists.txt` file in the component folder. If the
component should also be available in the host-version of the Toit SDK (for example for
testing), then this call must be in a file called `toit.cmake`. In that case, the
`CMakeLists.txt` file should contain an include of the `toit.cmake` file:

``` cmake
include("${CMAKE_CURRENT_LIST_DIR}/toit.cmake")
```

See the [echo](components/echo) component for an example.

## Callbacks

The `toit.h` header file contains documentation for the callbacks that can be registered,
but here is a brief overview.

Services can have the following callbacks:
- `on_created` - Called when a service is created. This is the first callback that is
  called, and it receives the "handler_context" which is needed if the service wants
  to send notifications. Often, the user-data object has a field to store that context.
- `on_message` - Called when a notification message is sent to the service. The
  callback receives the sender-id, a message, and the message-length. No response is
  expected, but services can use the sender id to send a notification back.
- `on_rpc_request` - Called when an RPC request is sent to the service. The callback
  receives the sender-id, a function-id, a request-handle, a message, and the
  message-length. The service must respond to the request by either calling
  `toit_msg_request_reply` or `toit_msg_request_fail`.
- `on_removed` - Called when the service is removed. This is the last callback that is
  called, and it is called after the service has been removed from the messaging
  system. The service should clean up any resources that it has allocated.

Example:

``` c
/// A function that echoes back the message it got.
static toit_err_t on_rpc_request(void* user_data, int sender, int function, toit_msg_request_handle_t handle, uint8_t* data, int length) {
  if (toit_msg_request_reply(handle, data, length, true) != TOIT_OK) {
    printf("unable to reply\n");
  }
  return TOIT_OK;
}
```

## Sending notifications

Services can send notifications to Toit containers by calling `toit_msg_notify`. The
function takes a handler-context, a receiver-id, a message, and the message-length. The
receiver-id must have been obtained from a message that was sent to the service.

Example:

``` c
uint8_t* data = (uint8_t*)malloc(5);
memcpy(data, "hello", 5);
toit_msg_notify(handler_context, target_id, data, 5, true);
```

The `target_id` is the id of a container that has already sent a message to the
service, at which point it was the sender-id of the message.

## Garbage collection

The Toit VM only runs the garbage collector when needed. As such, services that run in parallel
with the VM might encounter failed memory allocations more often than if they were running on
their own. It is therefore important to always check the return value of memory allocation
and to call `toit_gc` when such a call returns `NULL`, before trying to allocate memory again.

In some cases, it can also be advantageous to preemtively call `toit_gc` to avoid running out of
memory at a critical point, or at a memory location the user doesn't have control over.
