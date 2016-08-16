//sitar_time.h

//time in sitar is described by a tuple(cycle, phase).
//Each cycle consists of two phases: 0 and 1.
//time progresses as (n,0), (n,1), (n+1,0), (n+1,1),... where n is a natural number.


#ifndef SITAR_TIME_H
#define SITAR_TIME_H

#include<stdint.h>
#include<string>
#include<iostream>
#include<sstream>
#include<cassert>

namespace sitar{
	class time
	{

		uint64_t  _time;
		//bits 63 to 1 store the cycle
		//and bit 0 represents phase

		public:
		inline uint64_t cycle()const{return _time >>1;} //get cycle
		inline bool     phase()const{return _time & 1;}//get phase

		//constructor
		inline time()	{_time=0;}//initialize to (0,0)
		inline time(uint64_t cycle, bool phase){_time = (cycle<<1)|phase;}//specify cycle and phase
		inline time(const time& t){_time=t._time;}//copy constructor
		inline time(uint64_t t){_time=t;}//specify time as 64 bit value



		inline std::string toString()const 
		//convert to string. Example: time(10,0).getString() returns "(10,0)"
		{
			std::ostringstream os;
			os <<"("<<cycle()<<","<<phase()<<")";
			return os.str();
		};

		inline uint64_t toUint64()const {return _time;}


		
		//overloaded operators << = + -  += -= ++ -- == != > < >= <=
		//assignment
		inline time& operator=(const time& rhs)  { this->_time=rhs._time;    return *this; } 
		inline time& operator+=(const time& rhs) { this->_time += rhs._time; return *this; }
		inline time& operator-=(const time& rhs) 
		{
			assert("SITAR_TIME_UNDERFLOW" && this->_time >= rhs._time); 
			this->_time -= rhs._time; return *this; 
		}

		//arithmetic
		inline time operator+(const time& rhs)const { time temp(this->_time + rhs._time); return temp; }
		inline time operator-(const time& rhs)const 
		{ 
			assert("SITAR_TIME_UNDERFLOW" && this->_time >= rhs._time); 
			time temp(this->_time - rhs._time); return temp; 
		}


		//increment/decrement
		inline time& operator++()//prefix increment
		{ 
			this->_time +=1;          
			return *this; 
		}
		inline time& operator--()//prefix decrement
		{
			assert("SITAR_TIME_UNDERFLOW" && this->_time >= 1);
			this->_time-=1;
			return *this;
		}
		inline time operator++(int)//postfix increment
		{
			time temp(this->_time);
			this->_time += 1;
			return temp;
		}

		inline time operator--(int)//postfix decrement
		{
			assert("SITAR_TIME_UNDERFLOW" && this->_time >= 1);
			time temp(this->_time);
			this->_time -= 1;
			return temp;
		}


		//comparison
		inline bool operator==(const time& rhs)const { return(this->_time==rhs._time); }
		inline bool operator!=(const time& rhs)const { return(this->_time!=rhs._time); }
		inline bool operator< (const time& rhs)const { return(this->_time< rhs._time); }
		inline bool operator<=(const time& rhs)const { return(this->_time<=rhs._time); }
		inline bool operator> (const time& rhs)const { return(this->_time> rhs._time); }
		inline bool operator>=(const time& rhs)const { return(this->_time>=rhs._time); }

		friend inline std::ostream& operator<<(std::ostream& os, const time& t);

	
	};

		//friend function
		std::ostream& operator<<(std::ostream& os, const time& t)
		{ os<<"("<<(t._time>>1)<<","<<(t._time&1)<<")"; return os; }

}
#endif

