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
  static const String createOrderTitle = 'Новый заказ';
  static const String selectOrderType = 'Выберите вид заказа';
  static const String selectOrderTypeHint =
      'Укажите тип заявки — откроется форма с полями для этого вида заказа';
  static const String orderType = 'Вид заказа';
  static const String orderingFor = 'Торговая точка';
  static const String pullToRefresh = 'Потяните вниз для обновления';
  static const String noOrderTypes = 'Нет доступных типов заявок';
  static const String orderNumberRequired = 'Введите номер заказа';
  static const String supplierRequired = 'Введите поставщика';
  static const String deliveryDateRequired = 'Выберите дату отправки';
  static const String selectDate = 'Выберите дату';
  static const String stockBalance = 'Остаток';
  static const String noProducts = 'Нет товаров для этого типа заявки';
  static const String noDeliveryDates = 'Нет доступных дат отправки';
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
  static const String orderCreated = 'Заказ создан';

  // Order details
  static const String orderDetailsTitle = 'Детали заказа';
  static const String orderDetailsTab = 'Детали';
  static const String mainInfo = 'Основное';
  static const String orderNumber = 'Номер заказа';
  static const String customer = 'Заказчик';
  static const String supplier = 'Поставщик';
  static const String deliveryDate = 'Дата создание';
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
  static const String author = 'Автор';
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
  static const String close = 'Закрыть';
  static const String receiptSaved = 'Приёмка сохранена';
  static const String receiptItemsIncomplete =
      'Отметьте все позиции: принять или отклонить';
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
      'Вы уверены, что хотите завершить приёмку?';
  static const String receiptPreviewTitle = 'Предпросмотр приёмки';
  static const String receiptPreviewAccepted = 'Принято';
  static const String receiptPreviewRejected = 'Отклонено';
  static const String receiptPreviewPending = 'Не обработано';
  static const String receiptSaveConfirm = 'Сохранить приёмку по заказу?';

  // Force update
  static const String forceUpdateTitle = 'Требуется обновление';
  static const String forceUpdateMessage =
      'Вышло критическое обновление приложения. Для продолжения работы необходимо обновиться.';
  static const String forceUpdateButton = 'Обновить';

  // Placeholder screens
  static const String transfersPlaceholder = 'Перемещение товаров';
  static const String inventoryPlaceholder = 'Инвентаризация склада';

  // Nomenclature search (transfers)
  static const String nomenclatureSearchHint = 'Поиск номенклатуры';
  static const String transfersSearchPrompt =
      'Найдите товар по названию, коду или артикулу';
  static const String nomenclatureNoResults = 'Ничего не найдено';
  static const String clearSearch = 'Очистить';
}
