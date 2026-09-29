/// Localized UI strings (Russian labels per requirements).
abstract final class AppStrings {
  static const String appName = 'Production360';

  // Auth
  static const String loginTitle = 'Вход в систему';
  static const String login = 'Логин';
  static const String password = 'Пароль';
  static const String loginButton = 'Войти';
  static const String loginRequired = 'Введите логин';
  static const String passwordRequired = 'Введите пароль';
  static const String invalidCredentials = 'Неверный логин или пароль';
  static const String authError = 'Не удалось войти. Проверьте логин и пароль';
  static const String noAccessibleModules =
      'У вашей учётной записи нет доступа к разделам приложения. Обратитесь к администратору.';

  // Navigation
  static const String orders = 'Заявки';
  static const String transfers = 'Перемещение';
  static const String inventory = 'Инвентаризация';
  static const String retailOutlets = 'Торговые точки';
  static const String menu = 'Меню';
  static const String logout = 'Выйти';
  static const String profile = 'Профиль';
  static const String settings = 'Настройки';

  // Order tabs
  static const String pendingConfirmation = 'Ожидание подтверждения';
  static const String pendingDelivery = 'Ожидание доставки';
  static const String completed = 'Завершен';

  // Order card
  static const String orderId = 'Заявка №';
  static const String date = 'Дата';
  static const String status = 'Статус';
  static const String noOrders = 'Нет заявок. Создайте заявку через форму.';
  static const String noOrdersForWeek =
      'Нет завершённых заявок в выбранном периоде. Выберите другую дату в календаре выше.';
  static const String period = 'Период';
  static const String selectWeekHint = 'Выберите день — определится неделя';
  static const String noWarehouses = 'Нет доступных складов';

  // Create order
  static const String createOrder = 'Создать заказ';
  static const String createOrderAction = 'Создать';
  static const String createOrderTitle = 'Новый заказ';
  static const String selectOrderType = 'Выберите вид заказа';
  static const String selectOrderTypeHint =
      'Укажите тип заявки — откроется форма с полями для этого вида заказа';
  static const String orderType = 'Вид заказа';
  static const String accompanyingProduct = 'Сопутствующий товар';
  static const String orderingFor = 'Торговая точка';
  static const String pullToRefresh = 'Потяните вниз для обновления';
  static const String noOrderTypes = 'Нет доступных типов заявок';
  static const String orderNumberRequired = 'Введите номер заказа';
  static const String supplierRequired = 'Введите поставщика';
  static const String deliveryDateRequired = 'Выберите дату отгрузки';
  static const String selectDate = 'Выберите дату';
  static const String stockBalance = 'Остаток';
  static const String noProducts = 'Нет товаров для этого типа заявки';
  static const String noDeliveryDates = 'Нет доступных дат отгрузки';
  static const String atLeastOneItem = 'Укажите количество хотя бы для одной позиции';
  static const String organization = 'Организация';
  static const String organizationSender = 'Организация отправитель';
  static const String warehouse = 'Склад';
  static const String warehouseSender = 'Склад отправитель';
  static const String addItem = 'Добавить позицию';
  static const String removeItem = 'Удалить';
  static const String item = 'Позиция';
  static const String itemName = 'Название';
  static const String itemQuantity = 'Количество';
  static const String itemUnit = 'Ед. изм.';
  static const String unitHint = 'шт, кг';
  static const String itemNameRequired = 'Введите название';
  static const String itemQuantityRequired = 'Введите количество';
  static const String itemQuantityInvalid = 'Некорректное количество';
  static const String itemQuantityIntegerInvalid =
      'До запятой допускается не более 11 цифр';
  static const String itemQuantityFractionInvalid =
      'После запятой допускается не более 3 цифр';
  static const String orderCreated = 'Заказ создан';
  static const String createDocumentSavedHint =
      'Документ сохранён и недоступен для редактирования. Чтобы создать новый, вернитесь назад.';

  // Order details
  static const String orderDetailsTitle = 'Детали заказа';
  static const String orderDetailsTab = 'Детали';
  static const String mainInfo = 'Основное';
  static const String orderNumber = 'Номер заказа';
  static const String customer = 'Заказчик';
  static const String supplier = 'Поставщик';
  static const String deliveryDate = 'Дата создания';
  static const String shipmentDate = 'Дата отгрузки';
  static const String comment = 'Комментарий';
  static const String noComment = 'Комментарий не указан';
  static const String commentHint = 'Введите комментарий к заказу...';
  static const String orderItems = 'Позиции';
  static const String saveChanges = 'Сохранить изменения';
  static const String commentSaved = 'Комментарий сохранён';
  static const String orderReadOnlyHint =
      'Созданные и завершённые заказы недоступны для редактирования';
  static const String recipient = 'Получатель';
  static const String sender = 'Отправитель';
  static const String author = 'Автор';
  static const String authorCurrentUserBadge = 'Вы';
  static const String receiptItems = 'Приёмка';
  static const String receiptDecided = 'Обработанные позиции';
  static const String itemOrdered = 'Заказано';
  static const String itemShipped = 'Отгружено';
  static const String itemReceived = 'Получено';
  static const String receivedQuantity = 'Полученное количество';
  static const String noReceiptItems = 'Нет позиций для приёмки';
  static const String saveReceipt = 'Сохранить приёмку';
  static const String saveReceiptAction = 'Сохранить';
  static const String previewReceipt = 'Предпросмотр';
  static const String createOrderPreviewTitle = 'Предпросмотр заказа';
  static const String close = 'Закрыть';
  static const String receiptSaved = 'Приёмка сохранена';
  static const String receiptItemsIncomplete =
      'Отметьте все позиции: принять или отклонить';
  static const String receiptQuantitiesRequired =
      'Укажите полученное количество для принятых позиций';
  static const String acceptItem = 'Принять';
  static const String rejectItem = 'Отклонить';
  static const String createdDate = 'Дата создания';

  static const String cancel = 'Отмена';
  static const String yes = 'Да';
  static const String no = 'Нет';
  static const String confirmTitle = 'Вы уверены?';
  static const String confirmDefaultMessage = 'Подтвердите действие';
  static const String confirmCreateOrder =
      'Вы уверены, что хотите создать заказ?';
  static const String confirmSaveReceipt =
      'Вы уверены, что хотите сохранить приёмку?';
  static const String receiptPreviewTitle = 'Предпросмотр приёмки';
  static const String receiptPreviewAccepted = 'Принято';
  static const String receiptPreviewRejected = 'Отклонено';
  static const String receiptPreviewPending = 'Не обработано';

  // Force update
  static const String forceUpdateTitle = 'Требуется обновление';
  static const String forceUpdateMessage =
      'Вышло критическое обновление приложения. Для продолжения работы необходимо обновиться.';
  static const String forceUpdateButton = 'Обновить';
  static const String forceUpdateDesktopMessage =
      'Вышло критическое обновление. Установите новую версию приложения на компьютер.';
  static const String forceUpdateDesktopHint =
      'Обратитесь к администратору для установки новой версии.';

  // On-screen keyboard (desktop)
  static const String onScreenKeyboardShow = 'Экранная клавиатура';
  static const String onScreenKeyboardHide = 'Скрыть клавиатуру';
  static const String onScreenKeyboardSpace = 'Пробел';
  static const String onScreenKeyboardSymbols = '#+=';
  static const String onScreenKeyboardLetters = 'АБВ';

  // Placeholder screens
  static const String transfersPlaceholder = 'Перемещение товаров';
  static const String transfersComingSoon = 'Раздел временно недоступен';
  static const String inventoryPlaceholder = 'Инвентаризация склада';

  // Inventory (инвентаризация)
  static const String createInventory = 'Создать инвентаризацию';
  static const String createInventoryTitle = 'Новая инвентаризация';
  static const String inventoryDetailsTitle = 'Детали инвентаризации';
  static const String inventoryNumber = 'Инвентаризация №';
  static const String noInventoriesForWeek =
      'Нет инвентаризаций в выбранном периоде. Выберите другую дату в календаре выше.';
  static const String inventoryCreated = 'Инвентаризация создана';
  static const String confirmCreateInventory =
      'Вы уверены, что хотите создать инвентаризацию?';
  static const String inventoryItems = 'Товары';
  static const String inventoryNotFound = 'Документ инвентаризации не найден';
  static const String noInventoryItems = 'Нет позиций в документе';
  static const String inventorySearchPrompt =
      'Найдите товар по названию, коду или артикулу';
  static const String completeInventory = 'Завершить инвентаризацию';
  static const String confirmCompleteInventory =
      'Завершить инвентаризацию с указанными количествами?';
  static const String inventoryCompleted = 'Инвентаризация завершена';
  static const String inventoryReconciliationTitle = 'Сверка инвентаризации';
  static const String inventoryReconciliation = 'Сверка';
  static const String inventoryReconciliationAfterCreateHint =
      'Документ создан. Возврат к списку…';
  static const String inventoryReconciliationMatchHint =
      'Все позиции совпадают с учётным количеством.';
  static String inventoryReconciliationMismatchHint(int count) =>
      'Расхождений: $count';
  static const String inventoryMismatchBadge = 'Расхождение';
  static const String accountingQuantity = 'По учёту';
  static const String actualQuantity = 'Факт';
  static const String quantityDifference = 'Разница';
  static const String confirm = 'Подтвердить';

  // Production (производство)
  static const String production = 'Производство';
  static const String createProduction = 'Создать производство';
  static const String createProductionTitle = 'Новое производство';
  static const String productionDetailsTitle = 'Детали производства';
  static const String productionNumber = 'Производство №';
  static const String noProductionsForWeek =
      'Нет документов производства в выбранном периоде. Выберите другую дату в календаре выше.';
  static const String productionCreated = 'Производство создано';
  static const String confirmCreateProduction =
      'Вы уверены, что хотите создать производство?';
  static const String productionItems = 'Товары';
  static const String productionNotFound = 'Документ производства не найден';
  static const String noProductionItems = 'Нет позиций в документе';
  static const String productionSearchPrompt =
      'Найдите товар по названию, коду или артикулу';
  static const String productionWarehouse = 'Склад продукции';
  static const String rawMaterialsWarehouse = 'Склад сырья';
  static const String selectProductionWarehouse = 'Выберите склад продукции';
  static const String selectRawMaterialsWarehouse = 'Выберите склад сырья';
  static const String productionStructuralUnitError =
      '1С не смогла провести производство. Проверьте совместимость склада сырья с выбранной торговой точкой и настройки номенклатуры в 1С.';
  static const String productionUsagePlaces = 'Места использования';
  static const String productionUsagePlace = 'Место использования';
  static const String noProductionUsagePlaces = 'Места использования не указаны';

  // Transfers
  static const String createTransfer = 'Создать перемещение';
  static const String createTransferTitle = 'Новое перемещение';
  static const String transferDetailsTitle = 'Детали перемещения';
  static const String transferNumber = 'Перемещение №';
  static const String noTransfers =
      'Нет перемещений за выбранную дату';
  static const String noTransfersForWeek =
      'Нет перемещений в выбранном периоде. Выберите другую дату в календаре выше.';
  static const String transferCreated = 'Перемещение создано';
  static const String confirmCreateTransfer =
      'Вы уверены, что хотите создать перемещение?';
  static const String recipientWarehouse = 'Склад получатель';
  static const String selectRecipientWarehouse = 'Выберите склад получатель';
  static const String noRecipientWarehouses = 'Нет доступных складов получателей';
  static const String searchWarehouseHint = 'Поиск склада';
  static const String warehousesNotFound = 'Склады не найдены';
  static const String transferItems = 'Товары';
  static const String addProduct = 'Добавить товар';
  static const String transferNotFound = 'Документ перемещения не найден';
  static const String noTransferItems = 'Нет позиций в документе';

  // Nomenclature search (transfers create)
  static const String nomenclatureSearchHint = 'Поиск номенклатуры';
  static const String nomenclatureRootGroups = 'Группы номенклатуры';
  static const String nomenclatureGroups = 'Группы';
  static const String nomenclatureProducts = 'Товары';
  static const String nomenclatureShowProducts = 'Показать товары группы';
  static const String nomenclatureGlobalSearch = 'Поиск номенклатуры';
  static const String nomenclatureEmptyGroup =
      'Нет подгрупп или товаров для мобилки в этой группе. '
      'Проверьте галочку «Показывать в мобилке» в 1С или воспользуйтесь поиском';
  static const String transfersSearchPrompt =
      'Найдите товар по названию, коду или артикулу';

  // Write-offs (списание запасов)
  static const String writeoffs = 'Списание';
  static const String createWriteoff = 'Создать списание';
  static const String createWriteoffTitle = 'Новое списание';
  static const String writeoffDetailsTitle = 'Детали списания';
  static const String writeoffNumber = 'Списание №';
  static const String noWriteoffsForWeek =
      'Нет списаний в выбранном периоде. Выберите другую дату в календаре выше.';
  static const String writeoffCreated = 'Списание создано';
  static const String confirmCreateWriteoff =
      'Вы уверены, что хотите создать списание?';
  static const String writeoffItems = 'Товары';
  static const String writeoffNotFound = 'Документ списания не найден';
  static const String noWriteoffItems = 'Нет позиций в документе';
  static const String writeoffsSearchPrompt =
      'Найдите товар по названию, коду или артикулу';
  static const String writeoffReason = 'Причина списания';
  static const String selectWriteoffReason = 'Выберите причину списания';
  static const String noWriteoffReasons = 'Нет доступных причин списания';
  static const String searchWriteoffReasonHint = 'Поиск причины';
  static const String writeoffReasonsNotFound = 'Причины не найдены';

  // Returns (возврат поставщику)
  static const String returns = 'Возврат';
  static const String createReturn = 'Создать возврат';
  static const String createReturnTitle = 'Новый возврат';
  static const String confirmCreateReturn =
      'Вы уверены, что хотите создать возврат?';
  static const String returnCreated = 'Возврат создан';
  static const String returnDetailsTitle = 'Детали возврата';
  static const String returnNumber = 'Возврат №';
  static const String noReturnsForWeek =
      'Нет возвратов в выбранном периоде. Выберите другую дату в календаре выше.';
  static const String returnNotFound = 'Документ возврата не найден';
  static const String returnItems = 'Товары';
  static const String noReturnItems = 'Нет позиций в документе';
  static const String recipientOrganization = 'Организация получатель';
  static const String operationType = 'Вид операции';
  static const String documentSum = 'Сумма документа';
  static const String selectIncomingInvoice = 'Выберите приходную накладную';
  static const String noIncomingInvoices = 'Нет приходных накладных для возврата';
  static const String searchIncomingInvoiceHint = 'Поиск приходной накладной';
  static const String incomingInvoicesNotFound = 'Приходные накладные не найдены';
  static const String incomingInvoiceTitle = 'Приходная накладная';
  static const String incomingInvoiceNumber = 'Приходная №';
  static const String incomingInvoiceNotFound = 'Приходная накладная не найдена';
  static const String incomingInvoices = 'Приходные накладные';
  static const String itemPrice = 'Цена';
  static const String itemSum = 'Сумма';

  static const String nomenclatureNoResults = 'Ничего не найдено';
  static const String searchResultsFound = 'Найдено';
  static const String nomenclatureShown = 'Показано';
  static const String nomenclatureOf = 'из';
  static const String loadMoreNomenclature = 'Показать ещё';
  static const String productAdded = 'Добавлено';
  static const String tapToAdd = 'Добавить';
  static const String clearSearch = 'Очистить';

  // Printer
  static const String printerSettings = 'Принтер';
  static const String settingsAboutTitle = 'О приложении';
  static const String printerSettingsHint =
      'Ручное подключение принтера для текущего склада';
  static const String printerSettingsManualDescription =
      'Укажите IP-адрес и порт сетевого чекового принтера. '
      'По умолчанию используется порт 9100 (RAW TCP). '
      'При печати документа можно выбрать принтер из списка 1С.';
  static const String settingsPrintHint =
      'Список принтеров — при печати, ручной IP — в настройках.';
  static const String printerSelectionTitle = 'Выбор принтера';
  static const String printerSettingsDescription =
      'Выберите принтер из списка 1С или укажите IP вручную, '
      'если для склада принтеры не заданы.';
  static const String printerWarehouseTitle = 'Склад';
  static const String printerListTitle = 'Принтеры склада';
  static const String printerListEmpty =
      'Для этого склада принтеры не заданы в 1С. Введите IP вручную.';
  static const String printerManualEntry = 'Ручной ввод IP';
  static const String printerSelectRequired = 'Выберите принтер из списка';
  static const String printerLoadError = 'Не удалось загрузить список принтеров';
  static const String printerHost = 'IP-адрес принтера';
  static const String printerHostHint = '192.168.1.100';
  static const String printerHostRequired = 'Введите IP-адрес принтера';
  static const String printerPort = 'Порт';
  static const String printerPortInvalid = 'Некорректный порт (1–65535)';
  static const String printerSettingsSaved = 'Настройки принтера сохранены';
  static const String printDocument = 'Печать';
  static const String printSuccess = 'Документ отправлен на печать';
  static const String printNotConfiguredTitle = 'Принтер не настроен';
  static const String printOpenSettings = 'Настроить';
  static const String printTestAction = 'Тестовая печать';
  static const String printTestSuccess = 'Тестовый чек отправлен на печать';
  static const String printTestTitle = 'Тест печати';
  static const String printTestSubtitle = 'Production360';
  static const String printTestFooter =
      'Если этот чек напечатался корректно, принтер настроен.';
  static const String printPaperWidth = 'Ширина бумаги';
  static const String printPaperWidthValue = '80 мм';
  static const String printItemsSection = 'ПОЗИЦИИ';
  static const String printAppName = 'Production360';
  static const String printOrderTitle = 'ЗАЯВКА';
  static const String printTransferTitle = 'ПЕРЕМЕЩЕНИЕ';
  static const String printInventoryTitle = 'ИНВЕНТАРИЗАЦИЯ';
  static const String printWriteoffTitle = 'СПИСАНИЕ';
  static const String printProductionTitle = 'ПРОИЗВОДСТВО';
  static const String printerTestConnection = 'Проверить подключение';
  static const String printerConnectionOk =
      'Соединение с принтером установлено';
  static const String printerLogTitle = 'Журнал печати';
  static const String printerLogEmpty = 'Записей пока нет';
  static const String printerLogCopy = 'Копировать';
  static const String printerLogCopied = 'Журнал скопирован';
  static const String printerShowLog = 'Подробности';
  static const String printerLogHint =
      'При ошибках откройте журнал — там шаги подключения и код ошибки';
  static const String printerEncodingCp1251Hint =
      'Кодировка RK1048 (KZ-1048): русский, казахский и латиница по таблице принтера.';
  static const String printKazakhSampleLabel = 'Казахский';
  static const String printKazakhSampleText = 'Қазақша: Ұұ Әә Ғғ Ққ Ңң Өө Үү Іі';
}
