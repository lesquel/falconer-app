# Builds the Rust crate in ../../rust with cargokit and links it statically.
Pod::Spec.new do |s|
  s.name             = 'openmosh_core'
  s.version          = '0.0.1'
  s.summary          = 'OpenMosh Rust core (SSH, crypto) built with cargokit.'
  s.homepage         = 'https://github.com/lesquel/openmosh-app'
  s.license          = { :file => '../../LICENSE' }
  s.author           = { 'OpenMosh' => 'openmosh' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'
  s.platform         = :osx, '10.15'
  s.swift_version    = '5.0'

  s.script_phase = {
    :name => 'Build Rust library',
    # First argument is relative path to the Cargo crate, second is the library name.
    :script => 'sh "$PODS_TARGET_SRCROOT/../cargokit/build_pod.sh" ../../rust openmosh_core',
    :execution_position => :before_compile,
    :input_files => ['${BUILT_PRODUCTS_DIR}/cargokit_phony'],
    # Let Xcode know the static lib is an output so it waits for it before linking.
    :output_files => ['${BUILT_PRODUCTS_DIR}/libopenmosh_core.a'],
  }
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    # Keep every Rust symbol: Dart looks them up at runtime through FFI.
    'OTHER_LDFLAGS' => '-force_load ${BUILT_PRODUCTS_DIR}/libopenmosh_core.a',
  }
end
