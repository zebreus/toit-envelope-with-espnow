// Copyright (C) 2024 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the LICENSE file.

#include <toit/toit.h>

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

/// A struct to hold the context of the external service.
/// Typically, this would hold more data, but for this example, we only need
/// the message context.
typedef struct {
  toit_msg_context_t* msg_context;
} echo_service_t;

/// @brief Called when the external message handler is created.
/// @param user_data The user data passed to `toit_msg_add_handler`.
/// @param context The context of the external message handler. Calls to
///           `toit_msg_notify` and `toit_msg_remove_handler` need this context.
/// @return TOIT_ERR_SUCCESS. The only allowed return value.
static toit_err_t on_created(void* user_data, toit_msg_context_t* context) {
  echo_service_t* echo_service = (echo_service_t*)user_data;
  echo_service->msg_context = context;
  return TOIT_ERR_SUCCESS;
}

/// @brief Called when a notification message is received.
///
/// Echoes the message back to the sender.
/// Note that notifications are not required to be replied to.
///
/// @param user_data The user data passed to `toit_msg_add_handler`.
/// @param sender The id of the sender.
/// @param data The data of the message.
/// @param length The length of the message.
/// @return TOIT_ERR_SUCCESS. The only allowed return value.
static toit_err_t on_message(void* user_data, int sender, void* data, int length) {
  echo_service_t* echo_service = (echo_service_t*)user_data;
  toit_msg_context_t* context = echo_service->msg_context;
  if (toit_msg_notify(context, sender, data, length, true) != TOIT_ERR_SUCCESS) {
    printf("unable to send\n");
  }
  return TOIT_ERR_SUCCESS;
}

/// @brief Called when an RPC request is received.
///
/// For every RPC request the service must reply through either `toit_msg_request_reply` or
/// `toit_msg_request_fail`.
///
/// @param user_data The user data passed to `toit_msg_add_handler`.
/// @param sender The id of the sender.
/// @param function The function id of the request. For the echo service this is ignored.
/// @param handle The handle to reply to the request. This handle must be provided to either
///               `toit_msg_request_reply` or `toit_msg_request_fail`.
/// @param data The data of the request.
/// @param length The length of the request.
/// @return TOIT_ERR_SUCCESS. The only allowed return value.
static toit_err_t on_rpc_request(void* user_data, int sender, int function, toit_msg_request_handle_t handle, void* data, int length) {
  if (toit_msg_request_reply(handle, data, length, true) != TOIT_ERR_SUCCESS) {
    printf("unable to reply\n");
  }
  return TOIT_ERR_SUCCESS;
}

/// @brief Called when the external message handler is removed.
///
/// When this function is called, it is safe to free the user data.
///
/// @param user_data The user data passed to `toit_msg_add_handler`.
/// @return TOIT_ERR_SUCCESS. The only allowed return value.
static toit_err_t on_removed(void* user_data) {
  free(user_data);
  return TOIT_ERR_SUCCESS;
}

/// @brief  Register the external service.
static void __attribute__((constructor)) init() {
  echo_service_t* echo_service = (echo_service_t*)malloc(sizeof(echo_service_t));
  echo_service->msg_context = NULL;
  toit_msg_cbs_t cbs = {
    .on_created = &on_created,
    .on_message = &on_message,
    .on_rpc_request = &on_rpc_request,
    .on_removed = &on_removed,
  };
  toit_msg_add_handler("toitlang.org/demo-echo", echo_service, cbs);
}
