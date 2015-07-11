function [ outputEphemeris] = readRinexNav( filePath )
%readRinexNav Reads a mixed RINEX navigation file *.nav and returns the
%loaded ephemeris for each constellation
%   Reads Keplerian and Cartesian type ephemeris coming from RINEX 3.02
%   Files can be downlaoded from here: ftp://cddis.gsfc.nasa.gov/gnss/data/campaign/mgex/daily/rinex3/2015/
%   Download in *.p format and convert to .nav using rtklib

%%%%%-------Input
%       fileName = File adress

%%%%%------- Output
%       outputEphemeris = Class containing the ephemeris for each
%       constellation


'Loading ephemeris...'
endOfHeader = 0;

navFile = fopen(filePath);

%Read header
while (~endOfHeader)
    line = fgetl(navFile);
    lineSplit = strsplit(line);
    
    if strfind(line,'RINEX VERSION')
        Version = lineSplit(2);
        if ~strcmp(Version,'3.02')
            error 'Not the correct version, should be 3.02'
        end
        
        
    elseif strfind(line,'DATE')
        date = lineSplit(3);
        year = str2doubleq(date{1,1}(1:4));
        month = str2doubleq(date{1,1}(5:6));
        day = str2doubleq(date{1,1}(7:8));
        DOY=Date2DayOfYear(real(year),real(month),real(day));
    elseif strfind(line,'IONOSPHERIC CORR')
        if strcmp(lineSplit(1), 'GPSA')
            ionoAlpha = str2doubleq(lineSplit(2:5));
        elseif strcmp(lineSplit(1), 'GPSB')
            ionoBeta = str2doubleq(lineSplit(2:5));
        end
    elseif strfind (line,'LEAP SECONDS')
        leapSeconds = str2doubleq(lineSplit(2));
    elseif strfind(line,'END OF HEADER')
        endOfHeader = 1;
    end
end

%Pointer line set at the end of the header.
ionosphericParameters = [ionoAlpha; ionoBeta];


%read body

gpsEphemeris =  [];
glonassEphemeris = [];
beidouEphemeris = [];

keplerArray = zeros(22,1); %Vector containing Keplerian elements type ephemeris (GPS, Beidou, Galileo)
cartesianArray = zeros(19,1); %Vector containing Cartesian type ephemeris (GLONASS, SBAS)
while ~feof(navFile)
    line = fgetl(navFile);
    lineSplit = strsplit(line);
    
    constellation = line(1);
    if ischar(constellation) %New Ephemeris
        switch constellation
            case {'G', 'C'}                %If the ephemeris is ether for GPS or Beidou, store Keplerian elements
                
                %%Read All of the ephemeris
                svprn = str2doubleq([line(2), line(3)]);
                af0 = str2doubleq(lineSplit(end-2)); %Read from end because of 1 digit prn
                af1 = str2doubleq(lineSplit(end-1));
                af2 = str2doubleq(lineSplit(end));
                
                lineSplit = strsplit(fgetl(navFile));   %
                IODE = str2doubleq(lineSplit(2));
                crs = str2doubleq(lineSplit(3));
                deltan = str2doubleq(lineSplit(4));
                M0 = str2doubleq(lineSplit(5));
                
                lineSplit = strsplit(fgetl(navFile));	  %
                cuc = str2doubleq(lineSplit(2));
                ecc = str2doubleq(lineSplit(3));
                cus = str2doubleq(lineSplit(4));
                roota = str2doubleq(lineSplit(5));
                
                lineSplit = strsplit(fgetl(navFile));
                toe = str2doubleq(lineSplit(2));
                cic = str2doubleq(lineSplit(3));
                Omega0 = str2doubleq(lineSplit(4));
                cis = str2doubleq(lineSplit(5));
                
                lineSplit = strsplit(fgetl(navFile));	    %
                i0 =  str2doubleq(lineSplit(2));
                crc = str2doubleq(lineSplit(3));
                omega = str2doubleq(lineSplit(4));
                Omegadot = str2doubleq(lineSplit(5));
                
                lineSplit = strsplit(fgetl(navFile));	    %
                idot = str2doubleq(lineSplit(2));
                CodesOnL2 = str2doubleq(lineSplit(3));
                week_toe = str2doubleq(lineSplit(4));
                L2Pflag = str2doubleq(lineSplit(5));
                
                lineSplit = strsplit(fgetl(navFile));	    %
                SVaccuracy = str2doubleq(lineSplit(2));
                SVhealth = str2doubleq(lineSplit(3));
                tgd = str2doubleq(lineSplit(4));
                IODC = str2doubleq(lineSplit(5));
                
                lineSplit = strsplit(fgetl(navFile));
                transmissionTime = str2doubleq(lineSplit(2));
                fitInterval = str2doubleq(lineSplit(3));
                
                %Conversion to the format required by function
                %sat_coordinates_XYZ
                keplerArray(1)  = svprn;
                keplerArray(2)  = af2;
                keplerArray(3)  = M0;
                keplerArray(4)  = roota;
                keplerArray(5)  = deltan;
                keplerArray(6)  = ecc;
                keplerArray(7)  = omega;
                keplerArray(8)  = cuc;
                keplerArray(9)  = cus;
                keplerArray(10) = crc;
                keplerArray(11) = crs;
                keplerArray(12) = i0;
                keplerArray(13) = idot;
                keplerArray(14) = cic;
                keplerArray(15) = cis;
                keplerArray(16) = Omega0;
                keplerArray(17) = Omegadot;
                keplerArray(18) = toe;
                keplerArray(19) = af0;
                keplerArray(20) = af1;
                keplerArray(21) = toe;
                keplerArray(22) = tgd;
                
                if constellation == 'G'
                    gpsEphemeris =  [gpsEphemeris keplerArray];
                elseif constellation == 'C'
                    beidouEphemeris =  [beidouEphemeris keplerArray];
                else
                    error 'Unknown constellation'
                    %Should never reach this point, as there is a case
                    %above.
                end
                
            case 'R' %Also SBAS case
                slot_sv=str2doubleq(line(2:3));
                %Time of Emision
                ToE(1)=str2doubleq(lineSplit(end-8)); %Star from the end to avoid problems with 1 digit prn
                ToE(2)=str2doubleq(lineSplit(end-7));
                ToE(3)=str2doubleq(lineSplit(end-6));
                ToE(4)=str2doubleq(lineSplit(end-5));
                ToE(5)=str2doubleq(lineSplit(end-4));
                ToE(6)=str2doubleq(lineSplit(end-3));
                ToE = real(ToE);
                [toe,week]=Date2GPSTime(ToE(1),ToE(2),ToE(3),ToE(4)+ToE(5)/60+ToE(6)/3600);
                sv_clock_bias=str2doubleq(lineSplit(end-2));
                sv_rel_freq_bias=str2doubleq(lineSplit(end-1));
                m_f_t=str2doubleq(lineSplit(end));
                
                lineSplit = strsplit(fgetl(navFile));%%%
                X=str2doubleq(lineSplit(2));
                Xdot=str2doubleq(lineSplit(3));
                Xacc=str2doubleq(lineSplit(4));
                health=str2doubleq(lineSplit(5));
                
                lineSplit = strsplit(fgetl(navFile));%%%
                Y=str2doubleq(lineSplit(2));
                Ydot=str2doubleq(lineSplit(3));
                Yacc=str2doubleq(lineSplit(4));
                freq_num=str2doubleq(lineSplit(5));
                
                lineSplit = strsplit(fgetl(navFile));%%%
                Z=str2doubleq(lineSplit(2));
                Zdot=str2doubleq(lineSplit(3));
                Zacc=str2doubleq(lineSplit(4));
                age_oper_info=str2doubleq(lineSplit(5));
                
                cartesianArray(1)=slot_sv;
                cartesianArray(2)=toe;
                cartesianArray(3)=sv_clock_bias;
                cartesianArray(4)=sv_rel_freq_bias;
                cartesianArray(5)=m_f_t;
                cartesianArray(6)=X;
                cartesianArray(7)=Xdot;
                cartesianArray(8)=Xacc;
                cartesianArray(9)=health;
                cartesianArray(10)=Y;
                cartesianArray(11)=Ydot;
                cartesianArray(12)=Yacc;
                cartesianArray(13)=freq_num;
                cartesianArray(14)=Z;
                cartesianArray(15)=Zdot;
                cartesianArray(16)=Zacc;
                cartesianArray(17)=age_oper_info;
                cartesianArray(18)=1;
                cartesianArray(19)=week;
                
                if constellation == 'R'
                    glonassEphemeris = [glonassEphemeris, cartesianArray];
                elseif constellation == 'S'
                    
                    
                end
                
            otherwise
                %error 'Unknown constellation'
                
                
        end
        
    else
        error ('Wrong counting. New ephemeris expected.')
    end
    
end

% Construct output
outputEphemeris.glonassEphemeris        = real(glonassEphemeris);
outputEphemeris.gpsEphemeris            = real(gpsEphemeris);
outputEphemeris.beidouEphemeris         = real(beidouEphemeris);
outputEphemeris.ionosphericParameters   = real(ionosphericParameters);
outputEphemeris.DOY                     = real(DOY);
outputEphemeris.leapSeconds             = real(leapSeconds);


fclose(navFile);
'Ephemeris loaded correctly'


end
