# Registry port: provides the fxc tool from the installed Windows SDK
# instead of a prebuilt zip from https://vcpkg-prebuilt-sdks.ccpgames.com/fxc/fxc-v10.1.zip -
# a CCP-internal host (DNS resolves only to 10.1.1.180) unreachable outside that
# network. The tool itself is Microsoft's legacy HLSL shader compiler and ships
# with the Windows SDK already installed alongside VS BuildTools, so copying from
# the SDK is the correct reproducible source.
#
# This is the SDK-sourced recovery path previously carried as a project overlay
# (srt-carbon-ashes build-support/overlay-ports/fxc); upstreamed into the registry
# so clean Windows hosts need no project-only overlay.
#
# Output layout matches the legacy registry port: tools/fxc/fxc.exe +
# bin/D3dCompiler_47.dll.

# Locate the newest Windows Kits 10 bin\x64 that contains fxc.exe.
# $ENV{ProgramFiles(x86)} is not expressible in CMake (parens are invalid
# in $ENV{...} variable names), so check the fixed x86 default first, then
# the 64-bit %ProgramFiles% as a fallback.
set(_PF86 "C:/Program Files (x86)")
set(_WIN_KITS_BIN "${_PF86}/Windows Kits/10/bin")
if(NOT EXISTS "${_WIN_KITS_BIN}" AND DEFINED ENV{ProgramFiles})
    set(_WIN_KITS_BIN "$ENV{ProgramFiles}/Windows Kits/10/bin")
endif()
if(NOT EXISTS "${_WIN_KITS_BIN}")
    message(FATAL_ERROR
        "Windows SDK bin dir not found (tried '${_PF86}/Windows Kits/10/bin' "
        "and '%ProgramFiles%/Windows Kits/10/bin'). The Windows SDK component "
        "is required for the DX12 toolchain (install via the VS Build Tools "
        "installer: Windows 10/11 SDK).")
endif()

file(GLOB _FXC_CANDIDATES "${_WIN_KITS_BIN}/*/x64/fxc.exe")
list(SORT _FXC_CANDIDATES ORDER DESCENDING)
if(NOT _FXC_CANDIDATES)
    message(FATAL_ERROR
        "fxc.exe not found under '${_WIN_KITS_BIN}/<version>/x64'. "
        "The Windows SDK component is required for the DX12 toolchain (install via the "
        "VS Build Tools installer: Windows 10/11 SDK).")
endif()

set(_FXC_EXE "${_FXC_CANDIDATES}")
get_filename_component(_SDK_BIN_DIR "${_FXC_EXE}" DIRECTORY)
set(_D3DCOMPILER "${_SDK_BIN_DIR}/D3dCompiler_47.dll")
if(NOT EXISTS "${_D3DCOMPILER}")
    message(FATAL_ERROR "D3dCompiler_47.dll missing next to ${_FXC_EXE}")
endif()

message(STATUS "fxc: using ${_FXC_EXE}")

# Copy tool
file(MAKE_DIRECTORY "${CURRENT_PACKAGES_DIR}/tools/${PORT}")
file(COPY "${_FXC_EXE}" DESTINATION "${CURRENT_PACKAGES_DIR}/tools/${PORT}")
file(COPY "${_D3DCOMPILER}" DESTINATION "${CURRENT_PACKAGES_DIR}/bin")
vcpkg_copy_tool_dependencies("${CURRENT_PACKAGES_DIR}/tools/${PORT}")

# Usage
file(COPY "${CMAKE_CURRENT_LIST_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
