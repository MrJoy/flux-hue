You can normalize, for example,
the forward transform FFTW.fft(narray, -1, 0, 1)
(FFT regarding the first (dim 0) & second (dim 1) dimensions) by
dividing with (narray.shape[0]*narray.shape[1]). Likewise,
the result of FFTW.fft(narray, -1) (FFT for all dimensions)
can be normalized by narray.length.
