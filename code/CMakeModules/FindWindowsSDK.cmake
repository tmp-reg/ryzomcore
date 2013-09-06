# - Find Windows Platform SDK
# Find the Windows includes
#
#  WINSDK_INCLUDE_DIR - where to find Windows.h
#  WINSDK_INCLUDE_DIRS - where to find all Windows headers
#  WINSDK_LIBRARY_DIR - where to find libraries
#  WINSDK_FOUND       - True if Windows SDK found.

IF(WINSDK_FOUND)
  # If Windows SDK already found, skip it
  RETURN()
ENDIF(WINSDK_FOUND)

SET(WINSDK_VERSION "CURRENT" CACHE STRING "Windows SDK version to prefer")

MACRO(DETECT_WINSDK_VERSION_HELPER _ROOT _VERSION)
  GET_FILENAME_COMPONENT(WINSDK${_VERSION}_DIR "[${_ROOT}\\SOFTWARE\\Microsoft\\Microsoft SDKs\\Windows\\v${_VERSION};InstallationFolder]" ABSOLUTE)

  IF(WINSDK${_VERSION}_DIR AND NOT WINSDK${_VERSION}_DIR STREQUAL "/registry")
    SET(WINSDK${_VERSION}_FOUND ON)
    GET_FILENAME_COMPONENT(WINSDK${_VERSION}_VERSION_FULL "[${_ROOT}\\SOFTWARE\\Microsoft\\Microsoft SDKs\\Windows\\v${_VERSION};ProductVersion]" NAME)
    IF(NOT WindowsSDK_FIND_QUIETLY)
      MESSAGE(STATUS "Found Windows SDK ${_VERSION} in ${WINSDK${_VERSION}_DIR}")
    ENDIF(NOT WindowsSDK_FIND_QUIETLY)
  ELSEIF(WINSDK${_VERSION}_DIR AND NOT WINSDK${_VERSION}_DIR STREQUAL "/registry")
    SET(WINSDK${_VERSION}_DIR "")
  ENDIF(WINSDK${_VERSION}_DIR AND NOT WINSDK${_VERSION}_DIR STREQUAL "/registry")
ENDMACRO(DETECT_WINSDK_VERSION_HELPER)

MACRO(DETECT_WINSDK_VERSION _VERSION)
  SET(WINSDK${_VERSION}_FOUND OFF)
  DETECT_WINSDK_VERSION_HELPER("HKEY_CURRENT_USER" ${_VERSION})
  
  IF(NOT WINSDK${_VERSION}_FOUND)
    DETECT_WINSDK_VERSION_HELPER("HKEY_LOCAL_MACHINE" ${_VERSION})
  ENDIF(NOT WINSDK${_VERSION}_FOUND)
ENDMACRO(DETECT_WINSDK_VERSION)

SET(WINSDK_VERSIONS "8.0" "8.0A" "7.1" "7.0A" "6.1" "6.0" "6.0A")

# Search all supported Windows SDKs
FOREACH(_VERSION ${WINSDK_VERSIONS})
  DETECT_WINSDK_VERSION(${_VERSION})
ENDFOREACH(_VERSION)

IF(TARGET_ARM)
  SET(WINSDK8_SUFFIX "arm")
ELSEIF(TARGET_X64)
  SET(WINSDK8_SUFFIX "x64")
ELSEIF(TARGET_X86)
  SET(WINSDK8_SUFFIX "x86")
ENDIF(TARGET_ARM)

GET_FILENAME_COMPONENT(WINSDKCURRENT_VERSION "[HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Microsoft SDKs\\Windows;CurrentVersion]" NAME)

IF(WINSDKCURRENT_VERSION AND NOT WINSDKCURRENT_VERSION STREQUAL "/registry")
  IF(NOT WindowsSDK_FIND_QUIETLY)
#    MESSAGE(STATUS "Current version is ${WINSDKCURRENT_VERSION}")
  ENDIF(NOT WindowsSDK_FIND_QUIETLY)
ENDIF(WINSDKCURRENT_VERSION AND NOT WINSDKCURRENT_VERSION STREQUAL "/registry")

SET(WINSDKENV_DIR $ENV{WINSDK_DIR})

MACRO(USE_CURRENT_WINSDK)
  IF(WINSDKENV_DIR)
    SET(WINSDK_VERSION "")
    SET(WINSDK_VERSION_FULL "")
    SET(WINSDK_DIR ${WINSDKENV_DIR})
    FOREACH(_VERSION ${WINSDK_VERSIONS})
      IF(WINSDK_DIR STREQUAL WINSDK${_VERSION}_DIR)
        SET(WINSDK_VERSION ${_VERSION})
        SET(WINSDK_VERSION_FULL "${WINSDK${_VERSION}_VERSION_FULL}")
        BREAK()
      ENDIF(WINSDK_DIR STREQUAL WINSDK${_VERSION}_DIR)
    ENDFOREACH(_VERSION)
  ELSE(WINSDKENV_DIR)
    # Windows SDK 7.0A doesn't provide 64bits compilers, use SDK 7.1 for 64 bits
    IF(WINSDKCURRENT_VERSION STREQUAL WINSDK7.0A_VERSION_FULL)
      IF(TARGET_X64)
        SET(WINSDK_VERSION "7.1")
        SET(WINSDK_VERSION_FULL ${WINSDK7.1_VERSION_FULL})
        SET(WINSDK_DIR ${WINSDK7.1_DIR})
      ELSE(TARGET_X64)
        SET(WINSDK_VERSION "7.0A")
        SET(WINSDK_VERSION_FULL ${WINSDK7.0A_VERSION_FULL})
        SET(WINSDK_DIR ${WINSDK7.0A_DIR})
      ENDIF(TARGET_X64)
    ELSE(WINSDKCURRENT_VERSION STREQUAL WINSDK7.0A_VERSION_FULL)
      FOREACH(_VERSION ${WINSDK_VERSIONS})
        IF(WINSDKCURRENT_VERSION STREQUAL WINSDK${_VERSION}_VERSION)
          SET(WINSDK_VERSION ${_VERSION})
          SET(WINSDK_VERSION_FULL "${WINSDK${_VERSION}_VERSION_FULL}")
          SET(WINSDK_DIR "${WINSDK${_VERSION}_DIR}")
          BREAK()
        ENDIF(WINSDKCURRENT_VERSION STREQUAL WINSDK${_VERSION}_VERSION)
      ENDFOREACH(_VERSION)
    ENDIF(WINSDKCURRENT_VERSION STREQUAL WINSDK7.0A_VERSION_FULL)
  ENDIF(WINSDKENV_DIR)
ENDMACRO(USE_CURRENT_WINSDK)

IF(WINSDK_VERSION STREQUAL "CURRENT")
  USE_CURRENT_WINSDK()
ELSE(WINSDK_VERSION STREQUAL "CURRENT")
  IF(WINSDK${WINSDK_VERSION}_FOUND)
    SET(WINSDK_VERSION_FULL "${WINSDK${WINSDK_VERSION}_VERSION_FULL}")
    SET(WINSDK_DIR "${WINSDK${WINSDK_VERSION}_DIR}")
  ELSE(WINSDK${WINSDK_VERSION}_FOUND)
    USE_CURRENT_WINSDK()
  ENDIF(WINSDK${WINSDK_VERSION}_FOUND)
ENDIF(WINSDK_VERSION STREQUAL "CURRENT")

IF(WINSDK_DIR)
  MESSAGE(STATUS "Using Windows SDK ${WINSDK_VERSION}")
ELSE(WINSDK_DIR)
  MESSAGE(FATAL_ERROR "Unable to find Windows SDK!")
ENDIF(WINSDK_DIR)

# directory where Win32 headers are found
FIND_PATH(WINSDK_INCLUDE_DIR Windows.h
  HINTS
  ${WINSDK_DIR}/Include/um
  ${WINSDK_DIR}/Include
)

# directory where DirectX headers are found
FIND_PATH(WINSDK_SHARED_INCLUDE_DIR d3d9.h
  HINTS
  ${WINSDK_DIR}/Include/shared
  ${WINSDK_DIR}/Include
)

# directory where all libraries are found
FIND_PATH(WINSDK_LIBRARY_DIR ComCtl32.lib
  HINTS
  ${WINSDK_DIR}/Lib/win8/um/${WINSDK8_SUFFIX}
  ${WINSDK_DIR}/Lib
)

# signtool is used to sign executables
FIND_PROGRAM(WINSDK_SIGNTOOL signtool
  HINTS
  ${WINSDK_DIR}/Bin/x86
  ${WINSDK_DIR}/Bin
)

# midl is used to generate IDL interfaces
FIND_PROGRAM(WINSDK_MIDL midl
  HINTS
  ${WINSDK_DIR}/Bin/x86
  ${WINSDK_DIR}/Bin
)

IF(WINSDK_INCLUDE_DIR)
  SET(WINSDK_FOUND ON)
  SET(WINSDK_INCLUDE_DIRS ${WINSDK_INCLUDE_DIR} ${WINSDK_SHARED_INCLUDE_DIR})
  SET(CMAKE_LIBRARY_PATH ${WINSDK_LIBRARY_DIR} ${CMAKE_LIBRARY_PATH})
  INCLUDE_DIRECTORIES(${WINSDK_INCLUDE_DIRS})

  # Fix for using Windows SDK 7.1 with Visual C++ 2012
  IF(WINSDK_VERSION STREQUAL "7.1" AND MSVC11)
    ADD_DEFINITIONS(-D_USING_V110_SDK71_)
  ENDIF(WINSDK_VERSION STREQUAL "7.1" AND MSVC11)
ELSE(WINSDK_INCLUDE_DIR)
  IF(NOT WindowsSDK_FIND_QUIETLY)
    MESSAGE(STATUS "Warning: Unable to find Windows SDK!")
  ENDIF(NOT WindowsSDK_FIND_QUIETLY)
ENDIF(WINSDK_INCLUDE_DIR)
