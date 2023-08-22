import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

class CurlLoggerDioInterceptor extends Interceptor {
  final bool printOnSuccess;
  final bool convertFormData;
  final void Function(String msg)? logFunction;
  final Logger logger;

  CurlLoggerDioInterceptor({
    this.logFunction,
    this.printOnSuccess = true,
    this.convertFormData = true,
    Logger? customLogger,
  }) : logger = customLogger ?? defaultLogger();

  static Logger defaultLogger() => Logger(
        printer: PrettyPrinter(
          colors: false,
          lineLength: 0,
          methodCount: 0,
          errorMethodCount: 0,
          excludeBox: {Level.all: true},
          noBoxingByDefault: true,
          printEmojis: false,
        ),
        output: ConsoleOutput(),
      );

  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    if (printOnSuccess) {
      _renderCurlRepresentationResponse(response.requestOptions);
    }
    return handler.next(response); //continue
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _renderCurlRepresentationError(err.requestOptions);

    return handler.next(err); //continue
  }

  void _renderCurlRepresentationResponse(RequestOptions requestOptions) {
    // add a breakpoint here so all errors can break
    try {
      var msg = _cURLRepresentation(requestOptions);
      if (logFunction != null) {
        logFunction!(msg);
      } else {
        logger.log(Level.info, msg);
      }
    } catch (err) {
      logger.log(Level.error, 'unable to create a CURL representation of the requestOptions');
    }
  }

  void _renderCurlRepresentationError(RequestOptions requestOptions) {
    // add a breakpoint here so all errors can break
    try {
      var msg = _cURLRepresentation(requestOptions);
      if (logFunction != null) {
        logFunction!(msg);
      } else {
        logger.log(Level.error, msg);
      }
    } catch (err) {
      logger.log(Level.error, 'unable to create a CURL representation of the requestOptions');
    }
  }

  String _cURLRepresentation(RequestOptions options) {
    List<String> components = ['curl -i'];
    if (options.method.toUpperCase() != 'GET') {
      components.add('-X ${options.method}');
    }

    options.headers.forEach((k, v) {
      if (k != 'Cookie') {
        components.add('-H "$k: $v"');
      }
    });

    if (options.data != null) {
      // FormData can't be JSON-serialized, so keep only their fields attributes
      if (options.data is FormData && convertFormData == true) {
        options.data = Map.fromEntries(options.data.fields);
      }

      final data = options.data is String ? options.data : json.encode(options.data);
      components.add("-d '$data'");
    }

    components.add('"${options.uri.toString()}"');

    return components.join(' \\\n\t');
  }
}
