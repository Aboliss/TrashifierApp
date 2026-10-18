// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get binPlastic => 'Plástico';

  @override
  String get binPaper => 'Papel';

  @override
  String get binTrash => 'Basura general';

  @override
  String get binBio => 'Orgánico';

  @override
  String get binShortPlastic => 'Plástico';

  @override
  String get binShortPaper => 'Papel';

  @override
  String get binShortTrash => 'Basura';

  @override
  String get binShortBio => 'Orgánico';

  @override
  String get binHintPlastic => 'Botellas, envases';

  @override
  String get binHintPaper => 'Cajas, periódicos';

  @override
  String get binHintTrash => 'Todo lo demás';

  @override
  String get binHintBio => 'Comida y jardín';

  @override
  String get notificationTitlePlastic => 'Toca sacar el plástico';

  @override
  String get notificationTitlePaper => 'Toca sacar el papel';

  @override
  String get notificationTitleTrash => 'Toca sacar la basura';

  @override
  String get notificationTitleBio => 'Toca sacar el orgánico';

  @override
  String get notificationBodyPlastic =>
      '¡Acuérdate de sacar el cubo del plástico!';

  @override
  String get notificationBodyPaper => '¡Acuérdate de sacar el cubo del papel!';

  @override
  String get notificationBodyTrash =>
      '¡Acuérdate de sacar el cubo de la basura!';

  @override
  String get notificationBodyBio => '¡Acuérdate de sacar el cubo del orgánico!';

  @override
  String get headlineNothingPlanned => 'Aún no hay cubos previstos';

  @override
  String get moodSpooky => 'Día de cubos terrorífico';

  @override
  String get moodJolly => 'Día de cubos festivo';

  @override
  String get moodBig => 'Gran día de cubos';

  @override
  String get moodNormal => 'Día de cubos';

  @override
  String headlineToday(String mood) {
    return '¡$mood hoy!';
  }

  @override
  String headlineTomorrow(String mood) {
    return '¡$mood mañana!';
  }

  @override
  String headlineThisWeek(String weekday) {
    return 'Los cubos salen el $weekday';
  }

  @override
  String get headlineQuietWeek => 'Semana tranquila de cubos';

  @override
  String get today => 'Hoy';

  @override
  String get tomorrow => 'Mañana';

  @override
  String get yesterday => 'Ayer';

  @override
  String inDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'En $count días',
      one: 'En 1 día',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hace $count días',
      one: 'Hace 1 día',
    );
    return '$_temp0';
  }

  @override
  String inDaysBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'en $count días',
      one: 'en 1 día',
    );
    return '$_temp0';
  }

  @override
  String reminderTonight(String time) {
    return 'Recordatorio esta noche a las $time';
  }

  @override
  String reminderToday(String time) {
    return 'Recordatorio hoy a las $time';
  }

  @override
  String reminderTomorrow(String time) {
    return 'Recordatorio mañana a las $time';
  }

  @override
  String reminderOnDay(String weekday, String time) {
    return 'Recordatorio el $weekday a las $time';
  }

  @override
  String get pickupIsToday => 'La recogida es hoy';

  @override
  String get putBinsOutTonight => 'Saca los cubos esta noche';

  @override
  String emptyCardHintDayBefore(String time) {
    return 'Añade tus días de recogida y Bin Buddy te avisará el día anterior a las $time.';
  }

  @override
  String emptyCardHintPickupDay(String time) {
    return 'Añade tus días de recogida y Bin Buddy te avisará el mismo día a las $time.';
  }

  @override
  String dayRemindersDayBefore(int count, String time) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recordatorios el día anterior a las $time, uno por cubo.',
      one: 'Un recordatorio el día anterior a las $time.',
      zero: 'Sin cubos, sin recordatorio.',
    );
    return '$_temp0';
  }

  @override
  String dayRemindersPickupDay(int count, String time) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count recordatorios el día de la recogida a las $time, uno por cubo.',
      one: 'Un recordatorio el día de la recogida a las $time.',
      zero: 'Sin cubos, sin recordatorio.',
    );
    return '$_temp0';
  }

  @override
  String get nextPickupEyebrow => 'PRÓXIMA RECOGIDA';

  @override
  String get nothingPlanned => 'Nada previsto';

  @override
  String get addPickups => 'Añadir recogidas';

  @override
  String get next7Days => 'Próximos 7 días';

  @override
  String dayWithBins(String date, String bins) {
    return '$date: $bins';
  }

  @override
  String get comingUp => 'Próximamente';

  @override
  String get nothingElsePlanned => 'No hay nada más previsto.';

  @override
  String get remove => 'Quitar';

  @override
  String removeBinOnDay(String bin, String weekday) {
    return 'Quitar $bin del $weekday';
  }

  @override
  String removedSnack(String bin, String date) {
    return 'Se quitó $bin del $date';
  }

  @override
  String get undo => 'Deshacer';

  @override
  String get saveFailed => 'No se pudieron guardar las fechas.';

  @override
  String get navHome => 'Inicio';

  @override
  String get navCalendar => 'Calendario';

  @override
  String get swipeHint => 'Desliza a la izquierda para ver el calendario';

  @override
  String get settings => 'Ajustes';

  @override
  String get back => 'Atrás';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get done => 'Listo';

  @override
  String get addPickupsHint =>
      'Elige un cubo y toca todos sus días de recogida.';

  @override
  String upcomingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count próximas',
      zero: 'Nada previsto',
    );
    return '$_temp0';
  }

  @override
  String get whichBinsGoOut => '¿Qué cubos salen?';

  @override
  String get clearDay => 'Vaciar día';

  @override
  String saveBins(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Guardar $count cubos',
      one: 'Guardar 1 cubo',
    );
    return '$_temp0';
  }

  @override
  String binDays(String bin) {
    return 'Días de $bin';
  }

  @override
  String get tapDaysHint => 'Toca días para añadirlos o quitarlos';

  @override
  String changeAdded(int count) {
    return '+$count nuevos';
  }

  @override
  String changeRemoved(int count) {
    return '$count quitados';
  }

  @override
  String addDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Añadir $count días',
      one: 'Añadir 1 día',
    );
    return '$_temp0';
  }

  @override
  String removeDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Quitar $count días',
      one: 'Quitar 1 día',
    );
    return '$_temp0';
  }

  @override
  String get saveChanges => 'Guardar cambios';

  @override
  String get previousMonth => 'Mes anterior';

  @override
  String get nextMonth => 'Mes siguiente';

  @override
  String get filterAll => 'Todos';

  @override
  String get edit => 'Editar';

  @override
  String get noBinsThisDay =>
      'No sale ningún cubo. Toca Editar para añadir alguno.';

  @override
  String get specialHalloween => 'Halloween';

  @override
  String get specialChristmasEve => 'Nochebuena';

  @override
  String get specialChristmasDay => 'Navidad';

  @override
  String get specialBoxingDay => 'San Esteban';

  @override
  String get specialNewYearsEve => 'Nochevieja';

  @override
  String get sectionReminders => 'RECORDATORIOS';

  @override
  String get remindMe => 'Avísame';

  @override
  String get theDayBefore => 'El día anterior';

  @override
  String get onPickupDay => 'El día de la recogida';

  @override
  String get time => 'Hora';

  @override
  String get reminderTime => 'Hora del recordatorio';

  @override
  String reminderTimeA11y(String time) {
    return 'Hora del recordatorio, $time';
  }

  @override
  String get nextReminderLabel => 'Próximo recordatorio: ';

  @override
  String nextReminderAt(String date, String time) {
    return '$date a las $time';
  }

  @override
  String get nextReminderNone =>
      'Aún no hay ningún recordatorio. Añade recogidas en Inicio.';

  @override
  String get sectionAppearance => 'APARIENCIA';

  @override
  String get language => 'Idioma';

  @override
  String get phoneLanguage => 'Idioma del móvil';

  @override
  String phoneLanguageNow(String language) {
    return 'Idioma del móvil ($language)';
  }

  @override
  String get languageHint =>
      'También se usa en los widgets y los recordatorios.';

  @override
  String get theme => 'Tema';

  @override
  String get themeAuto => 'Auto';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get seasonalThemes => 'Temas de temporada';

  @override
  String get sectionBackup => 'COPIA DE SEGURIDAD';

  @override
  String get exportBackup => 'Exportar copia';

  @override
  String get exportBackupHint =>
      'Guarda todas las fechas de recogida en un archivo';

  @override
  String get importTitle => 'Importar';

  @override
  String get importHint =>
      'Desde una copia, un archivo compartido o un código QR';

  @override
  String get backupSaved => 'Copia guardada';

  @override
  String get sectionShare => 'COMPARTE CON TU CASA';

  @override
  String get sendAsFile => 'Enviar como archivo';

  @override
  String get showQrCode => 'Mostrar código QR';

  @override
  String get shareHint =>
      'Una copia única de tus próximas recogidas. Si las cambias más tarde, vuelve a compartirlas.';

  @override
  String get shareTitle => 'Calendario de Trashifier';

  @override
  String get nothingToShare => 'Aún no hay próximas recogidas que compartir';

  @override
  String get licenses => 'Licencias';

  @override
  String get importSheetHint =>
      'Puedes añadir las fechas a las tuyas o reemplazarlas.';

  @override
  String get fromFile => 'Desde un archivo';

  @override
  String get fromFileHint =>
      'Una copia o un calendario que alguien te ha enviado';

  @override
  String get scanQrCode => 'Escanear un código QR';

  @override
  String get scanQrCodeHint => 'Desde «Mostrar código QR» en el otro móvil';

  @override
  String get scannerUnavailable =>
      'El escáner QR no está disponible. Necesita los servicios de Google Play y, la primera vez, conexión a internet.';

  @override
  String get importFromFile => 'DESDE UN ARCHIVO';

  @override
  String get importFromLink => 'DESDE UN ENLACE';

  @override
  String get importFromQr => 'DESDE UN CÓDIGO QR';

  @override
  String importCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '¿Importar $count recogidas?',
      one: '¿Importar 1 recogida?',
    );
    return '$_temp0';
  }

  @override
  String skippedEntries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entradas no son válidas y se omitirán.',
      one: '1 entrada no es válida y se omitirá.',
    );
    return '$_temp0';
  }

  @override
  String currentPickups(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Ahora tienes $count recogidas. «Añadir» las conserva; «Reemplazar todo» las borra primero.',
      one:
          'Ahora tienes 1 recogida. «Añadir» la conserva; «Reemplazar todo» la borra primero.',
    );
    return '$_temp0';
  }

  @override
  String get addToMine => 'Añadir';

  @override
  String get replaceAll => 'Reemplazar todo';

  @override
  String get importButton => 'Importar';

  @override
  String importedSnack(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recogidas importadas',
      one: '1 recogida importada',
    );
    return '$_temp0';
  }

  @override
  String get errorNotTrashifier => 'Eso no es un calendario de Trashifier.';

  @override
  String get errorNewerVersion =>
      'Este calendario es de una versión más nueva de Trashifier. Actualiza la app primero.';

  @override
  String get errorTooLarge =>
      'Ese archivo es demasiado grande para ser un calendario.';

  @override
  String get errorInvalid =>
      'Este calendario está dañado y no se puede importar.';

  @override
  String get errorEmpty => 'Este calendario no tiene recogidas.';

  @override
  String get errorUnavailable => 'No disponible en este móvil.';

  @override
  String get errorFileFailed => 'No se pudo leer ni escribir el archivo.';

  @override
  String get qrTitle => 'Escanea para copiar el calendario';

  @override
  String qrSubtitle(int count, String range) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count próximas recogidas · $range',
      one: '1 próxima recogida · $range',
    );
    return '$_temp0';
  }

  @override
  String qrA11y(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Código QR con $count próximas recogidas',
      one: 'Código QR con 1 próxima recogida',
    );
    return '$_temp0';
  }

  @override
  String get qrHint =>
      'En el otro móvil, abre Trashifier › Ajustes › Importar › Escanear un código QR. La app siempre pregunta antes de importar nada.';

  @override
  String notificationTitleCustom(String bin) {
    return 'Toca sacar: $bin';
  }

  @override
  String notificationBodyCustom(String bin) {
    return '¡Acuérdate de sacar el cubo de $bin!';
  }

  @override
  String get sectionBins => 'CUBOS';

  @override
  String get addBin => 'Añadir un cubo';

  @override
  String get binsHint =>
      'Arrastra para reordenar. Los cubos ocultos conservan sus fechas, pero no se muestran ni avisan. Hasta 10 cubos.';

  @override
  String get binsFull => 'Ya hay 10 cubos, el máximo posible.';

  @override
  String get binHidden => 'Oculto';

  @override
  String showBin(String bin) {
    return 'Mostrar $bin';
  }

  @override
  String hideBin(String bin) {
    return 'Ocultar $bin';
  }

  @override
  String editBinA11y(String bin) {
    return 'Editar $bin';
  }

  @override
  String get newBinEyebrow => 'NUEVO CUBO';

  @override
  String get editBinEyebrow => 'EDITAR CUBO';

  @override
  String get binName => 'Nombre';

  @override
  String get binNameHint => 'p. ej., Vidrio';

  @override
  String binNameDefault(String name) {
    return 'Déjalo vacío para usar «$name»';
  }

  @override
  String get binColor => 'Color';

  @override
  String get binIcon => 'Icono';

  @override
  String binColorA11y(int number) {
    return 'Color $number';
  }

  @override
  String binIconA11y(int number) {
    return 'Icono $number';
  }

  @override
  String get addBinButton => 'Añadir cubo';

  @override
  String get deleteBin => 'Eliminar cubo';

  @override
  String deleteBinTitle(String bin) {
    return '¿Eliminar $bin?';
  }

  @override
  String deleteBinBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se eliminarán el cubo y sus $count fechas de recogida.',
      one: 'Se eliminarán el cubo y su única fecha de recogida.',
      zero: 'Se quitará el cubo.',
    );
    return '$_temp0';
  }

  @override
  String get delete => 'Eliminar';

  @override
  String binDeleted(String bin) {
    return 'Se eliminó $bin';
  }

  @override
  String importNewBins(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Añade $count cubos nuevos: $names.',
      one: 'Añade 1 cubo nuevo: $names.',
    );
    return '$_temp0';
  }

  @override
  String importNoRoom(String names) {
    return 'No hay sitio para $names: ya hay 10 cubos. Sus fechas se omitirán.';
  }
}
