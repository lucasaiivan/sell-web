/// Stub para plataformas no-web.
///
/// Lanza un error si se intenta usar en móvil/desktop nativo,
/// ya que en esas plataformas se debe usar path_provider + share_plus u otra librería.
void downloadFile(List<int> bytes, String fileName) {
  throw UnsupportedError(
    'downloadFile is only supported on Web. Use share_plus or file system on mobile/desktop.',
  );
}
