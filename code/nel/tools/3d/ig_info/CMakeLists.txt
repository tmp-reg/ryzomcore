FILE(GLOB SRC *.cpp *.h)

ADD_EXECUTABLE(ig_info ${SRC})

TARGET_LINK_LIBRARIES(ig_info nel3d nelmisc)
NL_DEFAULT_PROPS(ig_info "NeL, Tools, 3D: ig_info")
NL_ADD_RUNTIME_FLAGS(ig_info)

INSTALL(TARGETS ig_info RUNTIME DESTINATION ${NL_BIN_PREFIX} COMPONENT tools3d)
