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



float sdOctahedron(vec3 p, float s)
{
    p = abs(p);
    float m = p.x + p.y + p.z - s;
    vec3 r = 3.0*p - m;
    
#if 0
    // filbs111's version (see comments)
    vec3 o = min(r, 0.0);
    o = max(r*2.0 - o*3.0 + (o.x+o.y+o.z), 0.0);
    return length(p - s*o/(o.x+o.y+o.z));
#else
    // my original version
	vec3 q;
         if( r.x < 0.0 ) q = p.xyz;
    else if( r.y < 0.0 ) q = p.yzx;
    else if( r.z < 0.0 ) q = p.zxy;
    else return m*0.57735027;
    float k = clamp(0.5*(q.z-q.y+s),0.0,s); 
    return length(vec3(q.x,q.y-s+k,q.z-k)); 
#endif    
}

float sdfBox(vec3 p) 
{
    float boxRadius = 0.2;
    return length(max(abs(p) - boxRadius, 0));

}

float sdfSphere(vec3 p)
{
    float sphereRadius = 0.2;    
    // return length(p) - sphereRadius;
    return length(p) - sphereRadius;
}

float map( in vec3 pos )
{
    // float rad = 0.1*(0.5+0.5*sin(iTime*2.0));
    // return sdOctahedron(pos,0.5-rad) - rad;
    return sdfSphere(pos) - sdfBox(pos);
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
	vec3 cameraRayOrigin = vec3( someRadius * cos(angle), height,  someRadius * sin(angle) );
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
        const float tmax = 3.0;
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