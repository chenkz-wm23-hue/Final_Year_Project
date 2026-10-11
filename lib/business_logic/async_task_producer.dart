import 'dart:async';

/// Local async scheduling boundary for future recommendation/risk jobs.
/// This does not start a background server or persistent queue.
class AsyncTaskProducer {
  const AsyncTaskProducer();
  Future<T> submit<T>(FutureOr<T> Function() task) => Future<T>(task);
}
