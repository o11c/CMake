##section Variables specific to CPack DragNDrop generator
##end
##module
# - DragNDrop CPack generator (Mac OS X).
# The following variables are specific to the DragNDrop installers
# built on Mac OS X:
#end
#
##variable
#   CPACK_DMG_VOLUME_NAME - The volume name of the generated disk
#   image. Defaults to CPACK_PACKAGE_FILE_NAME.
##end
#
##variable
#   CPACK_DMG_FORMAT - The disk image format. Common values are UDRO
#   (UDIF read-only), UDZO (UDIF zlib-compressed) or UDBZ (UDIF
#   bzip2-compressed). Refer to hdiutil(1) for more information on
#   other available formats.
##end
#
##variable
#   CPACK_DMG_DS_STORE - Path to a custom .DS_Store file which e.g.
#   can be used to specify the Finder window position/geometry and
#   layout (such as hidden toolbars, placement of the icons etc.).
#   This file has to be generated by the Finder (either manually or
#   through OSA-script) using a normal folder from which the .DS_Store
#   file can then be extracted.
##end
#
##variable
#   CPACK_DMG_BACKGROUND_IMAGE - Path to an image file which is to be
#   used as the background for the Finder Window when the disk image
#   is opened.  By default no background image is set. The background
#   image is applied after applying the custom .DS_Store file.
##end
#
##variable
#   CPACK_COMMAND_HDIUTIL - Path to the hdiutil(1) command used to
#   operate on disk image files on Mac OS X. This variable can be used
#   to override the automatically detected command (or specify its
#   location if the auto-detection fails to find it.)
##end
#
##variable
#   CPACK_COMMAND_SETFILE - Path to the SetFile(1) command used to set
#   extended attributes on files and directories on Mac OS X. This
#   variable can be used to override the automatically detected
#   command (or specify its location if the auto-detection fails to
#   find it.)
##end
#
##variable
#   CPACK_COMMAND_REZ - Path to the Rez(1) command used to compile
#   resources on Mac OS X. This variable can be used to override the
#   automatically detected command (or specify its location if the
#   auto-detection fails to find it.)
##end

#=============================================================================
# Copyright 2006-2012 Kitware, Inc.
#
# Distributed under the OSI-approved BSD License (the "License");
# see accompanying file Copyright.txt for details.
#
# This software is distributed WITHOUT ANY WARRANTY; without even the
# implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the License for more information.
#=============================================================================
# (To distribute this file outside of CMake, substitute the full
#  License text for the above reference.)
