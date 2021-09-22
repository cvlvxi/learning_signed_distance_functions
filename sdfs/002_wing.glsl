// The MIT License
// Copyright © 2019 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


// EXACT distance to an octahedron. Most of the distance functions you'll find
// out there are not actually euclidan distances, but just approimxations that
// act as bounds. This implementation, while more involved, returns the true
// distance. This allows to do euclidean operations on the shape, such as 
// rounding (see http://iquilezles.org/www/articles/distfunctions/distfunctions.htm)
// while other implementations don't. Unfortunately the maths require us to do
// one square root sometimes to get the exact distance to the octahedron.

// List of other 3D SDFs: https://www.shadertoy.com/playlist/43cXRl
//
// and http://iquilezles.org/www/articles/distfunctions/distfunctions.htm
#version 330



uniform float iTime;
uniform vec2 iResolution;

const float pos_infinity = 1.0 / 0.0;

float feather( in vec3 pos, in vec3 line );

float wings( in vec3 pos, in vec3 topWing,  in vec3 bottomWing, in int numFeathers, in float featherWidth, in float featherLength ) {
    vec3 origin = vec3(0.0, 0.0, 0.0);
    vec3 wingEdge = bottomWing - topWing;
    
    float sdfVal = pos_infinity;

    for(int i=0; i<numFeathers; ++i) {
        float t = float(i) / (numFeathers-1);
        vec3 currentFeather = t*wingEdge + topWing;
        sdfVal = min(sdfVal, feather( pos, currentFeather) );
    } 

    return sdfVal;


}


float feather( in vec3 pos, in vec3 line ) {
    float lineRadius = 0.1;
    float lineDistance = length(line);

    // Calculate Basis Vector for Line
    vec3 ww = normalize(line);

    // Find closest point on the line
    float distanceOnLine = dot(ww, pos);
    vec3 pointOnLine = ww * distanceOnLine;

    // Check whether its on the line
    float distanceBehindLine = -distanceOnLine;
    float distanceBeyondLine = distanceOnLine - lineDistance;
    float outsideLine = length(pointOnLine - pos) - lineRadius;


    return max(distanceBehindLine, max(distanceBeyondLine, outsideLine));
}


float map( in vec3 pos )
{
    return wings(pos, vec3(2.0, 3.0-iTime, 0.0), vec3(0.0, -2.0, 0.0), 10, 20.0, 20.0);
}

// http://iquilezles.org/www/articles/normalsSDF/normalsSDF.htm
vec3 calcNormal( in vec3 pos )
{
    vec2 e = vec2(1.0,-1.0)*0.5773;
    const float eps = 0.0005;
    return normalize( e.xyy*map( pos + e.xyy*eps ) + 
					  e.yyx*map( pos + e.yyx*eps ) + 
					  e.yxy*map( pos + e.yxy*eps ) + 
					  e.xxx*map( pos + e.xxx*eps ) );
}
    
#define AA 10




void mainImage( out vec4 fragColor, in vec2 fragCoord )
{

    // camera movement	
	float angle = 0.5*(iTime-10.0);
    float someRadius = 0.9;
    float height = 0.5;

    // fixed rotation around y 
	// vec3 cameraRayOrigin = vec3( someRadius * cos(angle), height,  someRadius * sin(angle) );
    vec3 cameraRayOrigin = vec3(0.0, 0.0, 3.0);
    vec3 lookat = vec3( 0.0, 0.0, 0.0 );


    // Get the Basis Vectors for the Camera 
    // aka Camera Matrix
    vec3 ww = normalize( lookat - cameraRayOrigin );
    vec3 uu = normalize( cross(ww,vec3(0.0,1.0,0.0) ) );
    vec3 vv = normalize( cross(uu,ww));

    
    
    vec3 totalColor = vec3(0.0);
    
    #if AA>1
    for( int m=0; m<AA; m++ )
    for( int n=0; n<AA; n++ )
    {
        // pixel coordinates
        vec2 o = vec2(float(m),float(n)) / float(AA) - 0.5;
        vec2 p = (-iResolution.xy + 2.0*(fragCoord+o))/iResolution.y;
        #else    
        // Normalizing the pixel value to a value near to -1 to 1 
        // Conserving the aspect ratio 
        vec2 p = (-iResolution.xy + 2.0*fragCoord)/iResolution.y;
        #endif

	    // create view ray
        // Pixel in rd is in world coordinates
        float distanceToVirtualScreen = 1.5;
        vec3 rd = normalize( p.x*uu + p.y*vv + distanceToVirtualScreen*ww );

        // raymarch
        const float tmax = 10.0;
        float t = 0.0;
        for( int i=0; i<256; i++ )
        {
            vec3 pos = cameraRayOrigin + t*rd;
            float h = map(pos);
            if( h<0.0001 || t>tmax ) break;
            t += h;
        }
        
    
        // shading/lighting	
        vec3 col = vec3(0.0);
        if( t<tmax )
        {
            vec3 pos = cameraRayOrigin + t*rd;
            vec3 nor = calcNormal(pos);
            // vec3 direction of light 
            float dif = clamp( dot(nor,vec3(0.7,0.6,0.4)), 0.0, 1.0 );
            float amb = 0.5 + 0.5*dot(nor,vec3(0.0,0.8,0.6));
            col = vec3(0.2,0.3,0.4)*amb + vec3(0.8,0.7,0.5)*dif;
        }

        // gamma        
        col = sqrt( col );
	    totalColor += col;
    #if AA>1
    }
    totalColor /= float(AA*AA);
    #endif

	fragColor = vec4( totalColor, 1.0 );
}

out vec4 f_color;

void main() {
    mainImage(f_color, gl_FragCoord.xy);
}