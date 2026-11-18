// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get back => 'Atrás';

  @override
  String get close => 'Cerrar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get retry => 'Reintentar';

  @override
  String get save => 'Guardar';

  @override
  String get continueAction => 'Continuar';

  @override
  String get delete => 'Eliminar';

  @override
  String get dismiss => 'Descartar';

  @override
  String get notFound => 'No encontrado';

  @override
  String get logoSemanticLabel => 'Logo de Falconer';

  @override
  String get somethingWentWrong => 'Algo salió mal.';

  @override
  String get navHosts => 'Equipos';

  @override
  String get navInbox => 'Bandeja';

  @override
  String get navKeys => 'Claves';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get timeJustNow => 'justo ahora';

  @override
  String timeSecondsAgo(int count) {
    return 'hace $count s';
  }

  @override
  String timeMinutesAgo(int count) {
    return 'hace $count min';
  }

  @override
  String timeHoursAgo(int count) {
    return 'hace $count h';
  }

  @override
  String timeDaysAgo(int count) {
    return 'hace $count d';
  }

  @override
  String get greetingMorning => 'Buenos días';

  @override
  String get greetingAfternoon => 'Buenas tardes';

  @override
  String get greetingEvening => 'Buenas noches';

  @override
  String get hostKeyChangedTitle => 'La clave del equipo cambió';

  @override
  String get hostKeyChangedBody =>
      'El servidor presentó una clave distinta a la fijada al vincularlo. Esto puede significar que alguien está interceptando la conexión. La conexión se bloqueó. Si reinstalaste el equipo a propósito, elimínalo y vuelve a vincularlo.';

  @override
  String get fingerprintPinned => 'Fijada';

  @override
  String get fingerprintPresented => 'Presentada';

  @override
  String get noComputersTitle => 'Aún no hay equipos';

  @override
  String get noComputersBody =>
      'Ejecuta `falconer-hook pair` en tu equipo y luego escanea el código.';

  @override
  String get scanPairingCode => 'Escanear código de vinculación';

  @override
  String get addHostManually => 'Agregar equipo manualmente';

  @override
  String get allQuiet => 'Todo en calma.';

  @override
  String allGoodExcept(String alias, int more) {
    String _temp0 = intl.Intl.pluralLogic(
      more,
      locale: localeName,
      other: 'Todo bien,\nsalvo $alias y $more más.',
      zero: 'Todo bien,\nsalvo $alias.',
    );
    return '$_temp0';
  }

  @override
  String computersPairedNothingWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count equipos vinculados. Nada te está esperando.',
      one: '1 equipo vinculado. Nada te está esperando.',
    );
    return '$_temp0';
  }

  @override
  String agentWaitingForAnswer(String agent) {
    return '$agent espera tu respuesta.';
  }

  @override
  String inboxTileSemantics(int today, int waiting) {
    return 'Bandeja, $today eventos hoy, $waiting en espera';
  }

  @override
  String get today => 'Hoy';

  @override
  String eventCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count eventos',
      one: '1 evento',
    );
    return '$_temp0';
  }

  @override
  String waitingCount(int count) {
    return '$count en espera';
  }

  @override
  String get pairTileSemantics => 'Vincular un equipo con un código QR';

  @override
  String get addTile => 'Agregar';

  @override
  String get pairWithQr => 'Vincular con QR';

  @override
  String get yourComputers => 'Tus equipos';

  @override
  String get aHost => 'un equipo';

  @override
  String get host => 'equipo';

  @override
  String get needsYou => 'Te necesita';

  @override
  String reviewRequestSemantics(String alias, String agent, String what) {
    return 'Revisar solicitud de $alias, $agent: $what';
  }

  @override
  String get badgePush => 'push';

  @override
  String get badgeNoPush => 'sin push';

  @override
  String waitingForYou(int count) {
    return '$count te esperan';
  }

  @override
  String get terminal => 'Terminal';

  @override
  String get sessions => 'Sesiones';

  @override
  String get editHost => 'Editar equipo';

  @override
  String get deleteHost => 'Eliminar equipo';

  @override
  String get addHost => 'Agregar equipo';

  @override
  String get notificationsOn => 'Notificaciones activadas';

  @override
  String get notificationsOff => 'Notificaciones desactivadas';

  @override
  String get agentStateWaiting => 'en espera';

  @override
  String get agentStateWorking => 'trabajando';

  @override
  String get agentStateDone => 'listo';

  @override
  String get agentStateIdle => 'inactivo';

  @override
  String get agentStateUnknown => 'desconocido';

  @override
  String get shell => 'Shell';

  @override
  String get loadSessions => 'Cargar sesiones';

  @override
  String get refresh => 'Actualizar';

  @override
  String get enableNotifications => 'Activar notificaciones';

  @override
  String get noSessions => 'No hay sesiones de Herdr ni tmux';

  @override
  String sessionAttached(String kind) {
    return '$kind · conectada';
  }

  @override
  String get agents => 'Agentes';

  @override
  String get noAgents => 'No hay agentes en ejecución';

  @override
  String get pinnedHostKey => 'Clave del equipo fijada';

  @override
  String get openingHost => 'Abriendo equipo';

  @override
  String get deleteHostTitle => '¿Eliminar equipo?';

  @override
  String get deleteHostBody =>
      'Elimina el equipo, su clave fijada y su bandeja de este teléfono. Para quitar también este teléfono del equipo, revócalo antes en Dispositivos vinculados.';

  @override
  String get revokeThisPhoneTitle => '¿Revocar este teléfono?';

  @override
  String revokeDeviceTitle(String name) {
    return '¿Revocar $name?';
  }

  @override
  String revokeThisPhoneBody(String alias) {
    return 'Este es el teléfono que estás usando. Falconer perderá el acceso a $alias: el equipo elimina su clave SSH y su clave push. Vuelve a vincularlo para recuperar el acceso.';
  }

  @override
  String revokeDeviceBody(String alias) {
    return 'Elimina su clave SSH y su clave push de $alias. Ya no podrá conectarse ni recibir notificaciones.';
  }

  @override
  String get revoke => 'Revocar';

  @override
  String deviceRevoked(String name) {
    return 'Se revocó $name.';
  }

  @override
  String thisPhoneRevoked(String alias) {
    return 'Este teléfono se revocó de $alias. Vuelve a vincularlo o elimina el equipo.';
  }

  @override
  String get pairedDevices => 'Dispositivos vinculados';

  @override
  String get showPairedDevices => 'Mostrar dispositivos vinculados';

  @override
  String get noPairedDevices => 'No hay dispositivos vinculados con este equipo.';

  @override
  String get badgeThisPhone => 'este teléfono';

  @override
  String pairedOn(String date) {
    return 'Vinculado el $date';
  }

  @override
  String pairedOnStale(String date) {
    return 'Vinculado el $date · endpoint obsoleto';
  }

  @override
  String revokeDeviceTooltip(String name) {
    return 'Revocar $name';
  }

  @override
  String get fieldName => 'Nombre';

  @override
  String get fieldAddress => 'Nombre de host o IP de Tailscale';

  @override
  String get fieldPort => 'Puerto';

  @override
  String get fieldUser => 'Usuario';

  @override
  String get fieldKey => 'Clave';

  @override
  String get thisDeviceKey => 'Este dispositivo (Ed25519)';

  @override
  String get checkingHostKey => 'Verificando la clave del equipo…';

  @override
  String verifyHostKeyOf(String address) {
    return 'Verifica la clave del equipo $address';
  }

  @override
  String get verifyHostKeyHelp =>
      'En el equipo ejecuta:\n  ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub\nConfía en ella solo si la huella es idéntica. Quedará fijada y cualquier cambio posterior bloqueará la conexión.';

  @override
  String get presentedHostKey => 'Clave del equipo presentada';

  @override
  String get trustAndSave => 'Coincide: confiar y guardar';

  @override
  String get eventNotFound => 'Evento no encontrado';

  @override
  String get eventMayBeCleared => 'Puede que se haya borrado.';

  @override
  String get badgeQuestion => 'pregunta';

  @override
  String get badgeNeedsApproval => 'requiere aprobación';

  @override
  String get badgeSending => 'enviando…';

  @override
  String get badgeFailed => 'falló';

  @override
  String get badgeResolved => 'resuelto';

  @override
  String get badgeDone => 'listo';

  @override
  String get responseAllow => 'permitir';

  @override
  String get responseDeny => 'denegar';

  @override
  String get responseText => 'texto';

  @override
  String get noAgentEventsTitle => 'Aún no hay eventos de agentes.';

  @override
  String get noAgentEventsBody =>
      'Cuando un agente de un equipo vinculado te necesite, aparecerá aquí.';

  @override
  String get nothingWaiting => 'Nada te está esperando.';

  @override
  String requestsWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count solicitudes te esperan.',
      one: '1 solicitud te espera.',
    );
    return '$_temp0';
  }

  @override
  String agentOnHost(String agent, String alias) {
    return '$agent en $alias';
  }

  @override
  String agentAsks(String agent) {
    return '$agent pregunta';
  }

  @override
  String get agentNeedsYou => 'Un agente te necesita';

  @override
  String get alreadyAnswered => 'Ya respondido.';

  @override
  String get nothingToAnswer => 'Nada que responder.';

  @override
  String youPickedInNotification(String action) {
    return 'Elegiste \"$action\" en la notificación. Confírmalo abajo.';
  }

  @override
  String get approve => 'Aprobar';

  @override
  String get deny => 'Denegar';

  @override
  String get reply => 'Responder';

  @override
  String get replyToAgent => 'Responder al agente';

  @override
  String get openTerminal => 'Abrir terminal';

  @override
  String get sendReply => 'Enviar respuesta';

  @override
  String get asksVerificationBeforeSending =>
      'Pide tu huella o el bloqueo de pantalla antes de enviar.';

  @override
  String get confirmAnswerReason => 'Confirma tu respuesta al agente';

  @override
  String get pairAHost => 'Vincular un equipo';

  @override
  String get cameraPermissionDenied =>
      'Falconer no puede usar la cámara. Permítelo en Ajustes de Android > Aplicaciones > Falconer > Permisos > Cámara y luego toca Reintentar.';

  @override
  String get cameraUnavailable =>
      'No se pudo iniciar la cámara. Cierra las otras apps que la usan y toca Reintentar.';

  @override
  String get newComputer => 'Nuevo equipo';

  @override
  String pairWith(String ip) {
    return 'Vincular con $ip';
  }

  @override
  String get pairReviewSubtitle =>
      'El equipo se identifica con la clave del código; su nombre y la huella de su clave SSH se fijan a partir de su respuesta cifrada.';

  @override
  String get nameForThisPhone => 'Nombre para este teléfono';

  @override
  String get defaultDeviceName => 'Teléfono Android';

  @override
  String get defaultDeviceNameIphone => 'iPhone';

  @override
  String get defaultDeviceNameIpad => 'iPad';

  @override
  String get defaultDeviceNameMac => 'Mac';

  @override
  String get pairReviewNote =>
      'Esto crea una clave SSH en este teléfono, la autoriza en el equipo solo desde tu tailnet y registra notificaciones cifradas.';

  @override
  String get pairing => 'Vinculando…';

  @override
  String get pair => 'Vincular';

  @override
  String get pasteLinkLabel => 'O pega el enlace openmosh://pair';

  @override
  String get pasteLinkHelper => 'Muéstralo en el equipo con: falconer-hook pair --uri';

  @override
  String pairedWith(String alias) {
    return 'Vinculado con $alias';
  }

  @override
  String get pairedBody =>
      'Su clave SSH está fijada y las notificaciones están cifradas de extremo a extremo.';

  @override
  String get openHost => 'Abrir equipo';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get colors => 'Colores';

  @override
  String colorsSummary(String accent, String theme, String scheme) {
    return 'acento $accent · $theme · terminal $scheme';
  }

  @override
  String get themeSummarySystem => 'tema del sistema';

  @override
  String get themeSummaryLight => 'tema claro';

  @override
  String get themeSummaryDark => 'tema oscuro';

  @override
  String get notificationPreviews => 'Vista previa de notificaciones';

  @override
  String get notificationPreviewsBody =>
      'Desactivado: las notificaciones solo dicen \"<equipo>: <agente> te necesita\". Activado: muestran el texto de la solicitud, oculto en la pantalla de bloqueo.';

  @override
  String get keepConnected => 'Mantener las sesiones conectadas';

  @override
  String get keepConnectedBody =>
      'Las terminales siguen abiertas y se reconectan después de salir de ellas, hasta que te desconectes o cierres la app.';

  @override
  String get lockApp => 'Bloquear Falconer';

  @override
  String get lockAppBody =>
      'Pide tu huella, tu rostro o el bloqueo de pantalla al abrir Falconer y después de un minuto en segundo plano. Activarlo o desactivarlo también lo pide.';

  @override
  String terminalFontSize(String size) {
    return 'Tamaño de letra de la terminal · $size';
  }

  @override
  String get shortcutRow => 'Fila de atajos';

  @override
  String get presetNone => 'Ninguna';

  @override
  String get herdrPrefix => 'Prefijo de Herdr';

  @override
  String get language => 'Idioma';

  @override
  String get languageSystem => 'Sistema';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Español';

  @override
  String get privacy => 'Privacidad';

  @override
  String get privacyBody =>
      'Sin cuentas, analíticas ni informes de fallos. La app solo se comunica con tus equipos por Tailscale y con tu servidor UnifiedPush, que solo ve texto cifrado. Los modelos de voz se descargan solo cuando lo pides, y la voz se convierte en texto en el teléfono.';

  @override
  String get colorsCaption => 'Ajustes › Colores';

  @override
  String get sectionAccent => 'Acento';

  @override
  String get sectionApp => 'App';

  @override
  String get sectionTerminal => 'Terminal';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get contrastNote =>
      'Cada acento se comprueba con un contraste de 4.5:1 en los temas claro y oscuro.';

  @override
  String get preview => 'Vista previa';

  @override
  String accentSemantics(String accent) {
    return 'Acento $accent';
  }

  @override
  String schemeSemantics(String scheme) {
    return 'Terminal $scheme';
  }

  @override
  String get accentBlue => 'Azul';

  @override
  String get accentGreen => 'Verde';

  @override
  String get accentViolet => 'Violeta';

  @override
  String get accentAmber => 'Ámbar';

  @override
  String get accentCoral => 'Coral';

  @override
  String get accentWhite => 'Blanco';

  @override
  String get schemeBlack => 'Negro';

  @override
  String get schemePaper => 'Papel';

  @override
  String get schemeSepia => 'Sepia';

  @override
  String get schemeHighContrast => 'Alto contraste';

  @override
  String get schemeHighContrastShort => 'Alto';

  @override
  String get errHostKeyChanged => 'La clave del equipo cambió. La conexión se bloqueó.';

  @override
  String get errAuthRejected => 'El equipo rechazó la clave de este dispositivo.';

  @override
  String get errAuthTimeout =>
      'El equipo no respondió a la clave SSH. Si Tailscale SSH está activado en él, ejecuta: sudo tailscale set --ssh=false';

  @override
  String get errCannotReachHost => 'No se pudo conectar con el equipo.';

  @override
  String get errUnlockCancelled => 'Se canceló el desbloqueo.';

  @override
  String get errAddressNeedsNewCheck =>
      'Cambiar la dirección o el puerto requiere verificar de nuevo la clave del equipo. Vuelve a agregarlo.';

  @override
  String get errNoDistributor =>
      'No se encontró un distribuidor de UnifiedPush. Instala ntfy (F-Droid o GitHub) e inténtalo de nuevo.';

  @override
  String get errNeedsScreenLock =>
      'Configura un bloqueo de pantalla (PIN, patrón, contraseña o biometría) para guardar claves SSH.';

  @override
  String get errKeyInvalidated =>
      'El bloqueo de pantalla o la biometría cambió, así que esta clave ya no se puede desbloquear. Vuelve a vincular el equipo.';

  @override
  String get errPairingRejected =>
      'El equipo rechazó la vinculación. Comprueba que ambos dispositivos usen la misma cuenta de Tailscale y que el código siga siendo válido.';

  @override
  String get errPairingUnreachable =>
      'No se pudo conectar con el equipo. Comprueba que Tailscale esté activado y que falconer-hook pair siga en ejecución.';

  @override
  String get errInvalidPush => 'Se descartó un mensaje push no válido.';

  @override
  String get errEnterAddress => 'Escribe un nombre de host o una dirección IP.';

  @override
  String get errEnterUser => 'Escribe un nombre de usuario válido.';

  @override
  String get errEventNotFound => 'Evento no encontrado.';

  @override
  String get errFileTooLarge => 'Los archivos tienen un límite de 50 MB.';

  @override
  String get errNotPairedForPush => 'El equipo no está vinculado para push.';

  @override
  String get errInvalidFingerprint => 'Huella de la clave del equipo no válida.';

  @override
  String get errInvalidIdentifier => 'Identificador no válido.';

  @override
  String get errMessageTooLong => 'El mensaje supera los 4 KiB.';

  @override
  String get errNameLength => 'El nombre debe tener entre 1 y 64 caracteres.';

  @override
  String get errPairingReplyTooLarge => 'La respuesta de vinculación es demasiado grande.';

  @override
  String get errPairingRequestTooLarge => 'La solicitud de vinculación es demasiado grande.';

  @override
  String get errPortRange => 'El puerto debe estar entre 1 y 65535.';

  @override
  String get errHostClosed => 'El equipo cerró la conexión.';

  @override
  String get errHostTimeout => 'El equipo no respondió a tiempo.';

  @override
  String get errInvalidPairingResponse => 'El equipo envió una respuesta de vinculación no válida.';

  @override
  String get errPairingFailed => 'Falló la conexión de vinculación.';

  @override
  String get errDistributorNoAnswer =>
      'El distribuidor push no respondió. Abre ntfy y vuelve a intentarlo.';

  @override
  String get errDistributorRefused => 'El distribuidor push rechazó el registro.';

  @override
  String get errEndpointHttps => 'El endpoint push debe usar https.';

  @override
  String get errKeyMissing => 'Falta esta clave. Vuelve a vincular el equipo.';

  @override
  String get errUnexpectedPairingReply => 'Respuesta de vinculación inesperada.';

  @override
  String get errUnknownHost => 'Equipo desconocido.';

  @override
  String get errUnreadableFileSize => 'No se pudo leer el tamaño del archivo.';

  @override
  String get errWriteMessageFirst => 'Escribe un mensaje primero.';

  @override
  String get errHostCommandFailed => 'Falló el comando en el equipo.';

  @override
  String get errHookMissing => 'falconer-hook no está instalado en este equipo.';

  @override
  String get errHookUnexpectedOutput => 'falconer-hook devolvió una salida inesperada.';

  @override
  String get errUploadFailed => 'Falló la subida.';

  @override
  String get errDataTooLarge => 'Los datos son demasiado grandes.';

  @override
  String get errKeyImportFailed =>
      'Eso no es una clave privada ssh-ed25519, o la frase de contraseña no es correcta.';

  @override
  String get errNotUsableKey => 'Eso no es una clave privada ssh-ed25519 utilizable.';

  @override
  String get errLockStaysOff =>
      'No se pudo verificar tu identidad, así que el bloqueo sigue desactivado. Configura una huella, el rostro o un bloqueo de pantalla en este teléfono y vuelve a intentarlo.';

  @override
  String get errLockStaysOn =>
      'No se pudo verificar tu identidad, así que el bloqueo sigue activado.';

  @override
  String get errAlreadyAnswered => 'Este evento ya se respondió.';

  @override
  String get errReplyNotSubmitted =>
      'Tu respuesta se escribió pero no se envió. Pulsa Intro en la terminal.';

  @override
  String get terminalTitle => 'Terminal';

  @override
  String get terminalShell => 'shell';

  @override
  String terminalHostShell(String host) {
    return '$host · shell';
  }

  @override
  String terminalHostSession(String host, String kind) {
    return '$host · $kind';
  }

  @override
  String get terminalHostFallback => 'equipo';

  @override
  String get terminalSessionFallback => 'sesión';

  @override
  String get fullScreen => 'Pantalla completa';

  @override
  String get exitFullScreen => 'Salir de pantalla completa';

  @override
  String get disconnect => 'Desconectar';

  @override
  String get terminalChat => 'Chat';

  @override
  String get typeInTerminal => 'Escribir en la terminal';

  @override
  String get keyboard => 'Teclado';

  @override
  String get smallerText => 'Texto más pequeño';

  @override
  String get largerText => 'Texto más grande';

  @override
  String get paste => 'Pegar';

  @override
  String get addShortcut => 'Agregar atajo';

  @override
  String get copy => 'Copiar';

  @override
  String get clearSelection => 'Borrar selección';

  @override
  String get copied => 'Copiado';

  @override
  String removeShortcutTitle(String label) {
    return '¿Quitar \"$label\"?';
  }

  @override
  String get remove => 'Quitar';

  @override
  String get attachPhotos => 'Fotos';

  @override
  String get attachFile => 'Archivo';

  @override
  String get connecting => 'Conectando…';

  @override
  String get reconnecting => 'Reconectando…';

  @override
  String get chatAttach => 'Adjuntar imágenes o archivos';

  @override
  String get chatHint => 'Escribe al agente…';

  @override
  String get chatClose => 'Cerrar chat';

  @override
  String get chatSend => 'Enviar';

  @override
  String chatRemoveAttachment(String name) {
    return 'Quitar $name';
  }

  @override
  String get sessionEndedTitle => 'La sesión terminó.';

  @override
  String get sessionEndedBody => 'La shell del equipo se cerró. Iníciala de nuevo o vuelve atrás.';

  @override
  String get reconnect => 'Reconectar';

  @override
  String get shortcutCtrlKey => 'Ctrl + tecla';

  @override
  String get shortcutText => 'Texto';

  @override
  String get shortcutLetter => 'Letra';

  @override
  String get shortcutTextToSend => 'Texto a enviar';

  @override
  String get shortcutLabelOptional => 'Etiqueta (opcional)';

  @override
  String get shortcutPressEnter => 'Pulsar Enter después del texto';

  @override
  String get shortcutAdd => 'Agregar';

  @override
  String shortcutAddNamed(String label) {
    return 'Agregar $label';
  }

  @override
  String get moreKeys => 'Más teclas';

  @override
  String get fewerKeys => 'Menos teclas';

  @override
  String get keysTitle => 'Claves';

  @override
  String get keysEmpty =>
      'Aún no hay claves. Al emparejar se crea la clave de este dispositivo; también puedes generar o importar una.';

  @override
  String get generateKey => 'Generar clave';

  @override
  String get importKey => 'Importar clave';

  @override
  String get copyPublicKey => 'Copiar clave pública';

  @override
  String get publicKeyCopied => 'Clave pública copiada';

  @override
  String generatedKeyLabel(String date) {
    return 'Clave $date';
  }

  @override
  String get importedKeyLabel => 'Clave importada';

  @override
  String deleteKeyTitle(String label) {
    return '¿Eliminar $label?';
  }

  @override
  String get deleteKeyBody =>
      'Los equipos que usan esta clave dejarán de conectarse hasta que los vuelvas a emparejar.';

  @override
  String get importKeyTitle => 'Importar clave ssh-ed25519';

  @override
  String get keyLabel => 'Etiqueta';

  @override
  String get pastePrivateKey => 'Pega la clave privada de OpenSSH';

  @override
  String get importAction => 'Importar';

  @override
  String get lockedTitle => 'Falconer está bloqueado';

  @override
  String get lockedBody => 'Verifica que eres tú para continuar.';

  @override
  String get unlock => 'Desbloquear';

  @override
  String get lockPromptUnlock => 'Desbloquear Falconer';

  @override
  String get lockPromptTurnOn => 'Activar el bloqueo de Falconer';

  @override
  String get lockPromptTurnOff => 'Desactivar el bloqueo de Falconer';

  @override
  String get pairedWithoutPush =>
      'Las notificaciones están desactivadas: la app de notificaciones (ntfy) no respondió. Abre ntfy y luego toca Activar notificaciones en este equipo.';

  @override
  String get arrowUp => 'Arriba';

  @override
  String get arrowDown => 'Abajo';

  @override
  String get arrowLeft => 'Izquierda';

  @override
  String get arrowRight => 'Derecha';

  @override
  String get agentUsage => 'Uso de agentes';

  @override
  String get usageSubtitle => 'Tokens que registraron tus agentes en este equipo.';

  @override
  String get usagePeriod => 'Periodo';

  @override
  String usageDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
    );
    return '$_temp0';
  }

  @override
  String usagePeriodTotal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Últimos $count días',
      one: 'Último día',
    );
    return '$_temp0';
  }

  @override
  String usageBreakdown(String input, String output, String cache) {
    return 'Entrada $input · Salida $output · Caché $cache';
  }

  @override
  String get usagePlanLimits => 'Límites del plan';

  @override
  String usagePercentUsed(String percent) {
    return '$percent% usado';
  }

  @override
  String usageResetsIn(String time) {
    return 'Se reinicia en $time';
  }

  @override
  String get usageResetsSoon => 'Se reinicia pronto';

  @override
  String get usageProjects => 'Proyectos';

  @override
  String get usageModels => 'Modelos';

  @override
  String usageNotRecorded(int count) {
    return 'Sin registros ($count)';
  }

  @override
  String get usageNotRecordedHint => 'Estos agentes no dejan registros de uso locales para leer.';

  @override
  String get usageEmpty => 'No hay uso de agentes registrado en este periodo.';

  @override
  String get usageLoading => 'Leyendo el uso…';

  @override
  String get errHookOutdatedUsage => 'Actualiza falconer-hook en este equipo para ver el uso.';

  @override
  String get errUsagePeriod => 'El periodo debe ser de 1 a 31 días.';

  @override
  String get notifyHours => 'Horario de notificaciones';

  @override
  String get notifyHoursBody =>
      'Fuera de este horario los avisos igual llegan al inbox, sin sonido ni notificación.';

  @override
  String get notifyAlways => 'Siempre';

  @override
  String notifyBetween(String from, String to) {
    return '$from – $to';
  }

  @override
  String notifyUsesApp(String hours) {
    return 'Ajuste de la app: $hours';
  }

  @override
  String get notifyUseAppSetting => 'Usar el ajuste de la app';

  @override
  String get notifyOnlyBetween => 'Solo entre';

  @override
  String get notifyFrom => 'Desde';

  @override
  String get notifyTo => 'Hasta';

  @override
  String get appTheme => 'Tema';

  @override
  String get openHerdr => 'Abrir Herdr';

  @override
  String get openHerdrHint =>
      'Abre la sesión de Herdr con espejo: la computadora sigue la pestaña y el workspace que elijas aquí.';

  @override
  String get showSensitive => 'Mostrar';

  @override
  String get hideSensitive => 'Ocultar';

  @override
  String get showToCompare => 'Mostrar para comparar';

  @override
  String get copyPublicKeyTitle => '¿Copiar la clave pública?';

  @override
  String get copyPublicKeyBody =>
      'Se marca como sensible en el portapapeles. Pégala solo en computadoras de confianza.';

  @override
  String get verifyToShowTerminal => 'Verifica que eres tú para mostrar la terminal abierta';

  @override
  String get showFullText => 'Ver el texto completo';

  @override
  String get showLess => 'Ver menos';

  @override
  String get keyPassphrase => 'Frase de contraseña (si la clave tiene una)';

  @override
  String get chooseKeyFile => 'Elegir archivo';

  @override
  String get pairConfirmOnComputer =>
      'Confirma en tu computadora: escribe y en la terminal donde corre falconer-hook pair.';

  @override
  String get enterKey => 'Enter';

  @override
  String get voiceTitle => 'Dictado por voz';

  @override
  String get voiceSummaryNone => 'Sin modelo todavía: toca para configurarlo';

  @override
  String get voiceIntro =>
      'Dicta en el chat con el botón del micrófono. La voz se convierte en texto en este teléfono y el audio nunca se guarda ni se envía. Los modelos se descargan solo cuando tocas Descargar, una vez, y se quedan hasta que los borres.';

  @override
  String get voiceLanguage => 'Idioma hablado';

  @override
  String get voiceLanguageAuto => 'Automático';

  @override
  String get voiceLanguageAutoOnly => 'Este modelo detecta el idioma por sí solo.';

  @override
  String get voiceEnglishOnly => 'Solo inglés';

  @override
  String voiceLanguagesCount(int count) {
    return '$count idiomas';
  }

  @override
  String get voiceRecommended => 'Recomendado';

  @override
  String get voiceCustomBadge => 'Tu modelo';

  @override
  String get voiceModels => 'Modelos';

  @override
  String get voiceDownload => 'Descargar';

  @override
  String voiceDownloadTitle(String name) {
    return '¿Descargar $name?';
  }

  @override
  String voiceDownloadBody(String size, String host) {
    return 'Se descargarán $size desde $host y se verificará su SHA-256 antes de usarlo. Usa Wi-Fi si tus datos móviles son limitados.';
  }

  @override
  String voiceDownloadBodyUnknown(String host) {
    return 'El tamaño se conoce cuando empieza la descarga. Viene de $host y se verifica su SHA-256 antes de usarlo.';
  }

  @override
  String get voiceUnpacking => 'Verificando y descomprimiendo…';

  @override
  String get voiceVerifying => 'Verificando los archivos…';

  @override
  String get voiceCancelDownload => 'Cancelar descarga';

  @override
  String get voiceUse => 'Usar';

  @override
  String get voiceInUse => 'En uso';

  @override
  String get voiceDelete => 'Borrar modelo';

  @override
  String voiceDeleteTitle(String name) {
    return '¿Borrar $name?';
  }

  @override
  String get voiceDeleteBody =>
      'Los archivos se quitan del teléfono. Puedes volver a descargar el modelo más tarde.';

  @override
  String get voiceDeleteCustomBody => 'Se quitan del teléfono los archivos y esta entrada.';

  @override
  String voiceReady(String name) {
    return '$name está listo.';
  }

  @override
  String get voiceChecksum => 'La descarga no coincidió con su SHA-256 y se borró.';

  @override
  String get voiceMissingFiles =>
      'El archivo no tiene los archivos que necesita este tipo de modelo.';

  @override
  String get voiceUnsafe =>
      'Se rechazó el archivo: intenta escribir fuera de su carpeta o contiene enlaces.';

  @override
  String get voiceDownloadFailed => 'La descarga falló. Revisa la conexión e inténtalo de nuevo.';

  @override
  String get voiceAddCustom => 'Agregar un modelo';

  @override
  String get voiceAddCustomBody =>
      'Un archivo .tar.bz2 de sherpa-onnx por HTTPS, con su SHA-256. Se descarga solo cuando tocas Descargar.';

  @override
  String get voiceCustomName => 'Nombre';

  @override
  String get voiceCustomUrl => 'URL del archivo (https://…tar.bz2)';

  @override
  String get voiceCustomSha => 'SHA-256 del archivo';

  @override
  String get voiceCustomFamily => 'Tipo de modelo';

  @override
  String get voiceCustomLanguages => 'Idiomas (opcional, p. ej. es, en)';

  @override
  String get voiceErrName => 'Escribe un nombre.';

  @override
  String get voiceErrUrl => 'Usa una dirección https://.';

  @override
  String get voiceErrSha => 'Escribe los 64 caracteres hexadecimales del SHA-256.';

  @override
  String get voiceErrLanguages => 'Usa códigos de idioma como es, en, pt, separados por comas.';

  @override
  String get voiceDictate => 'Dictar';

  @override
  String get voiceStop => 'Detener y transcribir';

  @override
  String get voiceTranscribing => 'Transcribiendo…';

  @override
  String get voiceMicDenied => 'El dictado necesita el permiso del micrófono.';

  @override
  String get voiceFailed => 'No se pudo transcribir. Inténtalo de nuevo.';

  @override
  String get herdrNavigator => 'Agentes y workspaces';

  @override
  String get herdrNavigatorHint =>
      'Explora los workspaces, pestañas y agentes de Herdr y responde a los agentes con botones.';

  @override
  String get herdrStatusBlocked => 'te necesita';

  @override
  String get herdrFocused => 'en pantalla';

  @override
  String get herdrShellPane => 'Terminal';

  @override
  String get herdrNewWorkspace => 'Nuevo workspace';

  @override
  String get herdrNewTab => 'Nueva pestaña';

  @override
  String get herdrRename => 'Renombrar';

  @override
  String get herdrCreate => 'Crear';

  @override
  String get herdrStartAgent => 'Iniciar un agente';

  @override
  String get herdrStartAgentIn => 'Iniciar un agente en este panel';

  @override
  String herdrCloseWorkspaceTitle(String name) {
    return '¿Cerrar el workspace $name?';
  }

  @override
  String herdrCloseTabTitle(String name) {
    return '¿Cerrar la pestaña $name?';
  }

  @override
  String get herdrCloseBody => 'Todo lo que se ejecuta ahí en la computadora se detiene.';

  @override
  String get herdrName => 'Nombre';

  @override
  String get herdrNameOptional => 'Nombre (opcional)';

  @override
  String get herdrEmpty => 'Esta sesión de Herdr no tiene workspaces.';

  @override
  String get herdrNoTabs => 'Sin pestañas';

  @override
  String get herdrLoading => 'Leyendo Herdr…';

  @override
  String get herdrMoreActions => 'Más acciones';

  @override
  String get herdrPickPane => 'Elige un agente para verlo aquí.';

  @override
  String get herdrTerminalMode => 'Modo terminal';

  @override
  String get herdrGraphicMode => 'Modo gráfico';

  @override
  String get herdrNoFocusedPane => 'No hay ningún panel enfocado en Herdr.';

  @override
  String get herdrOutOfDate =>
      'Se muestra el último estado; intentando conectar con Herdr de nuevo.';

  @override
  String get agentViewCommand => 'Comando';

  @override
  String get agentViewEdit => 'Edición';

  @override
  String get agentViewStateRunning => 'En curso';

  @override
  String get agentViewStateSucceeded => 'Correcto';

  @override
  String get agentViewStateFailed => 'Falló';

  @override
  String get agentViewShowLess => 'Mostrar menos';

  @override
  String agentViewShowMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mostrar $count líneas más',
      one: 'Mostrar 1 línea más',
    );
    return '$_temp0';
  }

  @override
  String get agentViewLoadEarlier => 'Cargar anteriores';

  @override
  String get agentViewEmpty => 'El panel está vacío.';

  @override
  String agentViewNeedsPermission(String agent) {
    return '$agent necesita tu permiso';
  }

  @override
  String agentViewIsAsking(String agent) {
    return '$agent pregunta';
  }

  @override
  String get agentViewCurrentOption => 'opción actual';

  @override
  String get agentViewSending => 'enviando';

  @override
  String agentViewDraft(String text) {
    return 'Escrito en la computadora: $text';
  }

  @override
  String get herdrKeyUp => 'Arriba';

  @override
  String get herdrKeyDown => 'Abajo';

  @override
  String get herdrKeyEsc => 'Esc';

  @override
  String get herdrKeyEnter => 'Enter';

  @override
  String get herdrKeyTab => 'Tab';

  @override
  String get errHerdrInvalid => 'Herdr ya no tiene ese elemento. La lista se actualizó.';

  @override
  String get errHerdrNotRunning => 'Herdr no se está ejecutando en esta computadora.';

  @override
  String get errHerdrRefused => 'Herdr rechazó la solicitud.';

  @override
  String get errHerdrHookOutdated =>
      'Actualiza falconer-hook en esta computadora para usar el navegador de Herdr.';

  @override
  String get errMessageTooLong4000 => 'El mensaje tiene más de 4000 caracteres.';

  @override
  String get herdrViewAsAgents => 'Ver como agentes';

  @override
  String get herdrNewTerminal => 'Nueva terminal';

  @override
  String herdrAgentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count agentes',
      one: '1 agente',
    );
    return '$_temp0';
  }

  @override
  String herdrTerminalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count terminales',
      one: '1 terminal',
    );
    return '$_temp0';
  }

  @override
  String get herdrWorkspaceGone => 'Este workspace ya no está abierto.';

  @override
  String get herdrPickWorkspace => 'Elige un workspace para ver sus terminales.';

  @override
  String get webPushTitle => 'Notificaciones web (iOS / navegador)';

  @override
  String get webPushExplain =>
      'Instala la web app Falconer Notifications, activa las notificaciones allí, copia su código y pégalo aquí. No se aceptan enlaces que abran la app.';

  @override
  String get webPushStatusOff => 'Sin configurar';

  @override
  String webPushStatusOn(String service) {
    return 'Activas mediante $service';
  }

  @override
  String get webPushPasteHint => 'Pega el código';

  @override
  String get webPushReview => 'Revisar código';

  @override
  String get webPushTurnOff => 'Desactivar';

  @override
  String get webPushTurnedOff => 'Notificaciones web desactivadas.';

  @override
  String get webPushUse => 'Usar para notificaciones';

  @override
  String get webPushScreenTitle => 'Notificaciones web';

  @override
  String get webPushConfirmBody =>
      'Tus equipos vinculados usarán este registro para notificar a este dispositivo mediante la web app.';

  @override
  String get webPushServiceLabel => 'Servicio push';

  @override
  String webPushDestination(String service) {
    return 'Las notificaciones se enviarán a $service.';
  }

  @override
  String get webPushReplaces =>
      'Esto reemplaza el destino al que tus equipos vinculados envían las notificaciones web. Continúa solo si copiaste este código de tu propia web app Falconer Notifications.';

  @override
  String get webPushSending => 'Enviando a tus equipos…';

  @override
  String get webPushNoHosts =>
      'Aún no hay equipos vinculados. Vincula uno y lo recibirá automáticamente.';

  @override
  String webPushHostDelivered(String host) {
    return '$host: entregado';
  }

  @override
  String webPushHostPending(String host) {
    return '$host: pendiente, se enviará cuando el equipo se conecte';
  }

  @override
  String webPushHostTooOld(String host) {
    return '$host: actualiza falconer-hook (versión demasiado antigua)';
  }

  @override
  String get webPushDone => 'Listo';

  @override
  String get errWebPushCode => 'Este no es un código válido de notificaciones web.';

  @override
  String get errWebPushVersion =>
      'Este código de notificaciones web es de otra versión de Falconer. Actualiza la app.';
}
