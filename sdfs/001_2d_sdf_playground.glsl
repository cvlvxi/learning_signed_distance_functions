#version 330


uniform float iTime;
uniform vec2 iResolution;

float sdfCircle( in vec2 pos ) {
    // Pos in pixel land
    float radius = 200.0;
    return length(pos) - radius;
}


float sdfRectangle( in vec2 pos, in vec2 line ) {
    float lineRadius = 10.0;
    float lineDistance = length(line);
    
    vec2 normalizedLine = normalize(line);
    float distanceOnLine = dot(pos, normalizedLine);
    vec2 pointOnLine = normalizedLine * distanceOnLine;
    
    float sdfBehindLine = -distanceOnLine;
    float sdfBeyondLine = distanceOnLine - lineDistance;
    float sdfRect = length(pointOnLine - pos) - lineRadius;
    return max(sdfBehindLine, max(sdfBeyondLine, -500.0));
 ;
}


float sdf( in vec2 pos ) {
    return max(sdfRectangle( pos, vec2(cos(iTime) * 100.0, 100.0) ), sdfRectangle( pos, vec2(200.0, sin(iTime) * 100.0) ));
}



void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    //vec2 uv = fragCoord/iResolution.xy;
    
    vec2 normFragCoord = fragCoord.xy - iResolution.xy/2.0;
    
    float val = sdf(normFragCoord) / 500.0;
    
    if (abs(val) < 1.0/500.0) {
        fragColor = vec4(1.0, 1.0, 1.0, 1.0);
    } else {
        // Output to screen
        fragColor = vec4(max(val, .0), 0, max(-val, .0),1.0);
    }


}

out vec4 f_color;


void main() {
    mainImage(f_color, gl_FragCoord.xy);
}