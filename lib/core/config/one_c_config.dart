/// 1C HTTP service endpoints.
abstract final class OneCConfig {
  static const String baseUrl = 'https://1c.darasoft.kz:8443/unf/unf/hs';

  static const String authPath = '/mobile/auth';
  static const String orderTypesPath = '/mobile/zayavka/types';
  static const String orderTypeDataPath = '/mobile/zayavka/type/data';
  static const String ordersPath = '/mobile/zayavka';
  static const String internalTransferPath = '/mobile/internaltransfer';
  static const String internalTransferPredataPath =
      '/mobile/internaltransfer/predata';
  static const String internalTransferCreatePath =
      '/mobile/internaltransfer/create';
}
