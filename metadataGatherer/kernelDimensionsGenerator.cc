#include <fstream>

#include <traceEvent.h>
#include <kernelDimensionsGenerator.h>

#include <exception.h>

// Boost includes
#include <boost/filesystem.hpp>
#include <boost/archive/text_oarchive.hpp>
#include <boost/archive/text_iarchive.hpp>

//////////////////////////////////////////////////////////////////////////////////////////////////

trace::KernelDimensionsGenerator::Header::Header() {

}

//////////////////////////////////////////////////////////////////////////////////////////////////
		
unsigned int trace::KernelDimensionsGenerator::KernelDimensionsGenerator::_counter = 0;

trace::KernelDimensionsGenerator::KernelDimensionsGenerator() {
}
	
trace::KernelDimensionsGenerator::~KernelDimensionsGenerator() {
}

void trace::KernelDimensionsGenerator::initialize(const ir::ExecutableKernel& kernel) {
	_entry.name = kernel.name;
	_entry.module = kernel.module->path();
	_entry.format = KernelDimensionsFormat;

	std::string name = kernel.name;
	
	if( name.size() > 20 )
	{
		name.resize( 20 );
	}

	std::stringstream stream;
	stream << _entry.format << "_" << _counter++;

	boost::filesystem::path path( database );
	path = path.parent_path();
	path /= _entry.program + "_" + name + "_" + stream.str() 
		+ ".header";
	path = boost::filesystem::system_complete( path );
	
	_entry.header = path.string();
	
	_header.format = KernelDimensionsFormat;
	
	{
		//
		// this may not be strictly safe - a better solution is to improve the interface to
		// Executable kernel
		//
		/*
		const executive::EmulatedKernel * emuKernel = static_cast<const executive::EmulatedKernel * >(&kernel);
		
		_header.block = emuKernel->blockDim;
		_header.grid = emuKernel->gridDim;
		*/
	}
}

void trace::KernelDimensionsGenerator::event( const TraceEvent& event ) {
}
	
void trace::KernelDimensionsGenerator::finish() {

	_entry.updateDatabase( database );

	std::ofstream hfile( _entry.header.c_str() );
	boost::archive::text_oarchive harchive( hfile );

	if( !hfile.is_open() )
	{
		throw hydrazine::Exception(
			"Failed to open KernelDimensionsGenerator header file " 
			+ _entry.header );
	}
	
	harchive << _header;
	
	hfile.close();
}

