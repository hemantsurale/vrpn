# - Run doxygen on source files as a custom target
#
#  include(DoxygenTargets)
#  add_doxygen(<doxyfile> [OUTPUT_DIRECTORY <outputdir>]
#   [INSTALL_DESTINATION <installdir>
#   [INSTALL_COMPONENT <installcomponent>]
#   [INSTALL_PDF_NAME <installpdfname>] ]
#   [DOC_TARGET <targetname>]
#   [PROJECT_NUMBER <versionnumber>]
#   [NO_WARNINGS])
#
# Requires these CMake modules:
#  FindDoxygen
#
# Requires CMake 2.6 or newer (uses the 'function' command)
#
# Original Author:
# 2009-2010 Ryan Pavlik <rpavlik@iastate.edu> <abiryan@ryand.net>
# http://academic.cleardefinition.com
# Iowa State University HCI Graduate Program/VRAC

# We must run the following at "include" time, not at function call time,
# to find the path to this module rather than the path to a calling list file
get_filename_component(_doxygenmoddir ${CMAKE_CURRENT_LIST_FILE} PATH)

if(APPLE)
	list(APPEND CMAKE_PREFIX_PATH "/usr/texbin")
endif()

if(NOT DOXYGEN_FOUND)
	find_package(Doxygen QUIET)
endif()

set(DOXYGEN_LATEX "NO")
set(DOXYGEN_PDFLATEX "NO")
set(DOXYGEN_DOT "NO")

if(DOXYGEN_DOT_EXECUTABLE)
	set(DOXYGEN_DOT "YES")
endif()

find_package(LATEX QUIET)
if(LATEX_COMPILER AND MAKEINDEX_COMPILER)
	set(DOXYGEN_LATEX "YES")
endif()

if(PDFLATEX_COMPILER)
	set(DOXYGEN_PDFLATEX "YES")
endif()



function(add_doxygen _doxyfile)
	# parse arguments
	set(WARNINGS YES)
	set(_nowhere)
	set(_curdest _nowhere)
	set(_val_args
		OUTPUT_DIRECTORY
		DOC_TARGET
		INSTALL_DESTINATION
		INSTALL_COMPONENT
		INSTALL_PDF_NAME
		PROJECT_NUMBER)
	foreach(_val_arg ${_val_args})
		set(${_val_arg})
	endforeach()
	foreach(_element ${ARGN})
		list(FIND _val_args "${_element}" _val_arg_find)
		if("${_val_arg_find}" GREATER "-1")
			set(_curdest "${_element}")
		elseif("${_element}" STREQUAL "NO_WARNINGS")
			set(WARNINGS NO)
			set(_curdest _nowhere)
		else()
			list(APPEND ${_curdest} "${_element}")
		endif()
	endforeach()

	if(_nowhere)
		message(FATAL_ERROR "Syntax error in use of add_doxygen!")
	endif()

	if(NOT DOC_TARGET)
		set(DOC_TARGET doc)
	endif()

	if(NOT OUTPUT_DIRECTORY)
		set(OUTPUT_DIRECTORY "docs-generated")
	endif()

	if(NOT INSTALL_PDF_NAME)
		set(INSTALL_PDF_NAME "docs-generated.pdf")
	endif()

	if(NOT PROJECT_NUMBER)
		set(PROJECT_NUMBER "${CPACK_PACKAGE_VERSION}")
	endif()

	if(DOXYGEN_FOUND)
		if(NOT TARGET ${DOC_TARGET})

			if(NOT IN_DASHBOARD_SCRIPT)
				add_custom_target(${DOC_TARGET})
				set_target_properties(${DOC_TARGET}
					PROPERTIES
					EXCLUDE_FROM_ALL
					TRUE)
			else()
				add_custom_target(${DOC_TARGET} ALL)
			endif()
		endif()

		if(NOT IS_ABSOLUTE "${OUTPUT_DIRECTORY}")
			get_filename_component(OUTPUT_DIRECTORY
				"${CMAKE_CURRENT_BINARY_DIR}/${OUTPUT_DIRECTORY}"
				ABSOLUTE)
		endif()

		set_property(DIRECTORY
			APPEND
			PROPERTY
			ADDITIONAL_MAKE_CLEAN_FILES
			"${OUTPUT_DIRECTORY}/html"
			"${OUTPUT_DIRECTORY}/latex")

		get_filename_component(_doxyfileabs "${_doxyfile}" ABSOLUTE)
		get_filename_component(INCLUDE_FILE "${_doxyfileabs}" NAME)
		get_filename_component(INCLUDE_PATH "${_doxyfileabs}" PATH)

		if(DOXYGEN_LATEX)
			set(GENERATE_LATEX YES)
		else()
			set(GENERATE_LATEX NO)
		endif()

		if(DOXYGEN_PDFLATEX)
			set(USE_PDFLATEX YES)
		else()
			set(USE_PDFLATEX NO)
		endif()

		if(DOXYGEN_DOT)
			set(HAVE_DOT YES)
			set(DOT_PATH ${DOXYGEN_DOT_PATH})
		else()
			set(HAVE_DOT NO)
			set(DOT_PATH "")
		endif()

		# See http://www.cmake.org/pipermail/cmake/2006-August/010786.html
		# for info on this variable
		if("${CMAKE_BUILD_TOOL}" MATCHES "(msdev|devenv)")
			set(WARN_FORMAT "\"$file($line) : $text \"")
		else()
			set(WARN_FORMAT "\"$file:$line: $text \"")
		endif()

		configure_file("${_doxygenmoddir}/DoxygenTargets.doxyfile.in"
			"${CMAKE_CURRENT_BINARY_DIR}/${_doxyfile}.additional"
			ESCAPE_QUOTES
			@ONLY)

		add_custom_command(TARGET
			${DOC_TARGET}
			COMMAND
			${DOXYGEN_EXECUTABLE}
			"${CMAKE_CURRENT_BINARY_DIR}/${_doxyfile}.additional"
			WORKING_DIRECTORY
			"${CMAKE_CURRENT_SOURCE_DIR}"
			#MAIN_DEPENDENCY ${DOC_TARGET}
			COMMENT
			"Running Doxygen with configuration ${_doxyfile}..."
			VERBATIM)

		if(DOXYGEN_PDFLATEX)
			add_custom_command(TARGET
				${DOC_TARGET}
				POST_BUILD
				COMMAND
				${CMAKE_MAKE_PROGRAM}
				WORKING_DIRECTORY
				"${OUTPUT_DIRECTORY}/latex"
				COMMENT
				"Generating PDF using PDFLaTeX..."
				VERBATIM)
		endif()

		if(INSTALL_DESTINATION)
			if(INSTALL_COMPONENT)
				install(DIRECTORY
					"${OUTPUT_DIRECTORY}/html"
					DESTINATION
					"${INSTALL_DESTINATION}"
					COMPONENT
					"${INSTALL_COMPONENT}")
				if(DOXYGEN_PDFLATEX)
					install(FILES "${OUTPUT_DIRECTORY}/latex/refman.pdf"
						DESTINATION "${INSTALL_DESTINATION}"
						COMPONENT "${INSTALL_COMPONENT}"
						RENAME "${INSTALL_PDF_NAME}")
				endif()

			else()
				install(DIRECTORY
					"${OUTPUT_DIRECTORY}/html"
					DESTINATION
					"${INSTALL_DESTINATION}")
				if(DOXYGEN_PDFLATEX)
					install(FILES "${OUTPUT_DIRECTORY}/latex/refman.pdf"
						DESTINATION "${INSTALL_DESTINATION}"
						RENAME "${INSTALL_PDF_NAME}")
				endif()
			endif()
		endif()

	endif()
endfunction()
