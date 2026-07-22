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
  static const String stockWriteoffPath = '/mobile/spisaniyezapasov';
  static const String stockWriteoffPredataPath =
      '/mobile/spisaniyezapasov/predata';
  static const String stockWriteoffCreatePath =
      '/mobile/spisaniyezapasov/create';
  static const String inventoryPath = '/mobile/invent';
  static const String inventoryCreatePath = '/mobile/invent/create';
  static const String productionPath = '/mobile/proizvodstvo';
  static const String productionPredataPath = '/mobile/proizvodstvo/predata';
  static const String productionCreatePath = '/mobile/proizvodstvo/create';
}
