notes = 2*[261.63, 277.18, 293.66, 311.13, 329.63, 349.23, 369.99, 392, 415.3, 440, 466.16, 493.88];
prescaler = 64;
f_clk = 16000000;
init = 256-(f_clk/prescaler)./(2.*notes);

disp("min: "+min(init))
disp("max: "+max(init))

init