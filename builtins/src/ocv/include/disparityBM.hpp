#ifndef DISPARITYBM
#define DISPARITYBM

//////////////////////////////////////////////////////////////////////////////
// Transpose and copy matrix. The size of input matrix, output matrix, and
// the region to copy can be different. The other pixels are set to 0.  
// Although the function is templetized, it is currently only compiled for single.
// OpenCV supports int16 and single. We may choose to add int16 support later.
//////////////////////////////////////////////////////////////////////////////
template<class T>
void transposeAndPad(T* in, T* out, 
                     mwSize numValidRows, mwSize numValidCols,
                     mwSize numOutRows,   mwSize numOutCols,
                     mwSize numInRows)
{
    mwSize r, c;
    for(c=0; c<numValidCols; c++)
    {
        for(r=0; r<numValidRows; r++)
        {
            out[r*numOutCols+c] = in[c*numInRows+r];
        }

        // Pad the right border
        for(; r<numOutRows; r++)
        {
            out[r*numOutCols+c] = 0;
        }
    }

    // Pad the bottom border
    for(; c<numOutCols; c++)
    {
        for(r=0; r<numOutRows; r++) {
            out[r*numOutCols+c] = 0;
        }
    }
}

template<class T>
void copyAndPadRM(T* in, T* out,
	mwSize numValidRows, mwSize numValidCols,
	mwSize numOutRows, mwSize numOutCols,
	mwSize numInRows)
{
	mwSize r, c;
	for (r = 0; r<numValidRows; r++)
	{
		for (c = 0; c<numValidCols; c++)
		{
			*out++ = *in++;
		}

		// Pad the right border
		for (; c<numOutCols; c++)
		{
			*out++ = 0;
		}
	}

	// Pad the bottom border
	for (; r<numOutRows; r++)
	{
		for (c = 0; c<numOutCols; c++) {
			*out++ = 0;
		}
	}
}

//////////////////////////////////////////////////////////////////////////////
// Transpose, copy, and clip matrix. The size of input matrix, output matrix, 
// and the region to copy can be different. Pixels with value of invalidValue
// are set to -FLT_MAX. Pixels at the last "borderWidth" rows are set to 
// -FLT_MAX, too.
//////////////////////////////////////////////////////////////////////////////
template<class T>
void transposeAndClip(T* in, T* out,
                      mwSize numValidRows, mwSize numValidCols,
                      mwSize numOutRows,   mwSize numOutCols,
                      mwSize numInRows,    T invalidValue, mwSize borderWidth)
{
    mwSize r, c;
    for(c=0; c<numValidCols; c++)
    {
        for(r=0; r<numValidRows-borderWidth; r++)
        {
            T val = in[c*numInRows+r];
            out[r*numOutCols+c] = (val != invalidValue ? in[c*numInRows+r] : -FLT_MAX);
        }

        // Overwrite pixels at the right border
        for(; r<numOutRows; r++)
        {
            out[r*numOutCols+c] = -FLT_MAX;
        }
    }

    // Overwrite pixels at the bottom border
    for(; c<numOutCols; c++)
    {
        for(r=0; r<numOutRows; r++)
        {
            out[r*numOutCols+c] = -FLT_MAX;
        }
    }
}

template<class T>
void copyAndClipRM(T* in, T* out,
	mwSize numValidRows, mwSize numValidCols,
	mwSize numOutRows, mwSize numOutCols,
	mwSize numInRows, T invalidValue, mwSize borderWidth)
{
	mwSize r, c;
	for (r = 0; r<numValidRows-borderWidth; r++)
	{
		for (c = 0; c<numValidCols; c++)
		{
			T val = *in++;
			*out++ = (val != invalidValue ? val : -FLT_MAX);
		}

		// Pad the right border
		for (; c<numOutCols; c++)
		{
			*out++ = -FLT_MAX;
		}
	}

	// Pad the bottom border
	for (; r<numOutRows; r++)
	{
		for (c = 0; c<numOutCols; c++) {
			*out++ = -FLT_MAX;
		}
	}
}

inline void transposeClipAndCastBM(int16_T* in, real32_T* out,
                      mwSize numValidRows, mwSize numValidCols,
                      mwSize numOutRows,   mwSize numOutCols,
                      mwSize numInRows,    int16_T invalidValue, mwSize borderWidth)
{
    mwSize r, c;
    for(c=0; c<numValidCols; c++)
    {
        for(r=0; r<numValidRows-borderWidth; r++)
        {
            int16_T val = in[c*numInRows+r];
            int16_T fractionalPart = 0x000f & val;
            if (val > invalidValue)
            {
                out[r*numOutCols+c] = (real32_T)(in[c*numInRows+r] >> 4);
                // Adding back the 4 bit fractional part, *0.0625 to shift it by 2^-4.
                out[r*numOutCols+c] += (real32_T)(fractionalPart*0.0625);
            }
            else
            {
                out[r*numOutCols+c] = -FLT_MAX;
            }
        }

        // Overwrite pixels at the right border
        for(; r<numOutRows; r++)
        {
            out[r*numOutCols+c] = -FLT_MAX;
        }
    }

    // Overwrite pixels at the bottom border
    for(; c<numOutCols; c++)
    {
        for(r=0; r<numOutRows; r++)
        {
            out[r*numOutCols+c] = -FLT_MAX;
        }
    }
}

inline void copyClipAndCastBMRM(int16_T* in, real32_T* out,
	mwSize numValidRows, mwSize numValidCols,
	mwSize numOutRows, mwSize numOutCols,
	mwSize numInRows, int16_T invalidValue, mwSize borderWidth)
{
	mwSize r, c;
	for (r = 0; r<numValidRows - borderWidth; r++)
	{
		for (c = 0; c<numValidCols; c++)
		{
			int16_T val = *in++;
			int16_T fractionalPart = 0x000f & val;
			if (val > invalidValue)
			{
				*out = (real32_T)((*in++) >> 4);
				// Adding back the 4 bit fractional part, *0.0625 to shift it by 2^-4.
				*out++ += (real32_T)(fractionalPart*0.0625);
			}
			else
			{
				*out++ = -FLT_MAX;
			}
		}

		// Pad the right border
		for (; c<numOutCols; c++)
		{
			*out++ = -FLT_MAX;
		}
	}

	// Pad the bottom border
	for (; r<numOutRows; r++)
	{
		for (c = 0; c<numOutCols; c++) {
			*out++ = -FLT_MAX;
		}
	}
}

#endif
