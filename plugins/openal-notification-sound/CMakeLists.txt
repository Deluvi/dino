find_packages(OPENAL_NOTIFICATION_SOUND_PACKAGES REQUIRED
    OpenAL
    Gee
    GLib
    GModule
    GObject
    GTK3
)

set(RESOURCE_LIST
    message2_mono_16_44100.raw
)

compile_gresources(
    OPENAL_NOTIFICATION_SOUND_GRESOURCES_TARGET
    OPENAL_NOTIFICATION_SOUND_GRESOURCES_XML
    TARGET ${CMAKE_CURRENT_BINARY_DIR}/resources/resources.c
    TYPE EMBED_C
    RESOURCES ${RESOURCE_LIST}
    PREFIX /im/dino/Dino/openal-notification-sound
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/data
)

vala_precompile(OPENAL_NOTIFICATION_SOUND_VALA_C
SOURCES
    src/plugin.vala
    src/register_plugin.vala
CUSTOM_VAPIS
    ${CMAKE_BINARY_DIR}/exports/xmpp-vala.vapi
    ${CMAKE_BINARY_DIR}/exports/dino.vapi
    ${CMAKE_BINARY_DIR}/exports/qlite.vapi
    ${CMAKE_CURRENT_SOURCE_DIR}/vapi/openal.vapi
PACKAGES
    ${OPENAL_NOTIFICATION_SOUND_PACKAGES}
GRESOURCES
    ${OPENAL_NOTIFICATION_SOUND_GRESOURCES_XML}
)

add_definitions(${VALA_CFLAGS})
add_library(openal-notification-sound SHARED ${OPENAL_NOTIFICATION_SOUND_VALA_C} ${OPENAL_NOTIFICATION_SOUND_GRESOURCES_TARGET})
target_link_libraries(openal-notification-sound libdino openal ${OPENAL_NOTIFICATION_SOUND_PACKAGES})
set_target_properties(openal-notification-sound PROPERTIES PREFIX "")
set_target_properties(openal-notification-sound PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/plugins/)

install(TARGETS openal-notification-sound ${PLUGIN_INSTALL})
