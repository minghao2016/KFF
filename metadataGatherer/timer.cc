#ifndef TIMER_CPP_INCLUDED
#define TIMER_CPP_INCLUDED

#include <timer.h>
#include <sstream>

namespace meta
{
	std::string Timer::toString() const
	{
		std::stringstream stream;
		
		#ifdef HAVE_TIME_H
			stream << seconds() << "s (" << cycles() << " ns)";
		#else
			stream << seconds() << "s (" << cycles() << " ticks)";
		#endif
		
		return stream.str();
	}
}

#endif

