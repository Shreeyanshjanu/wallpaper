import 'package:flutter/material.dart';
import 'dart:ui_web' as ui_web;
import 'dart:html' as html;
import 'canvas_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final String viewId =
      'three-js-view-${DateTime.now().millisecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();

    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry.registerViewFactory(
      viewId,
      (int viewId) {
        final iframe = html.IFrameElement()
          ..style.border = 'none'
          ..style.height = '100%'
          ..style.width = '100%'
          ..srcdoc = _getHtmlContent();

        // Listen for messages from iframe
        html.window.onMessage.listen((event) {
          if (event.data == 'navigate_to_canvas') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CanvasScreen(),
              ),
            );
          }
        });

        return iframe;
      },
    );
  }

  String _getHtmlContent() {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <script src="https://cdn.jsdelivr.net/npm/three@0.150.0/build/three.min.js"></script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/gsap/3.12.2/gsap.min.js"></script>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body { height: 100%; overflow: hidden; }
    html { font-size: 1vw; }
    body { cursor: grab; user-select: none; background: #000; }
    body:active { cursor: grabbing; }
    .grid { position: fixed; top: 0; left: 0; width: 150%; height: 150%; display: grid; grid-template-columns: repeat(5, 1fr); }
    .grid > div { position: relative; }
    canvas { position: fixed; top: 0; left: 0; width: 100%; height: 100%; pointer-events: none; }
    figure { position: absolute; inset: 0.5rem; padding: 0; margin: 0; }
    
    /* Navigation Button */
    .nav-button {
      position: fixed;
      top: 40px;
      right: 40px;
      width: 80px;
      height: 80px;
      background: white;
      border-radius: 16px;
      cursor: pointer;
      z-index: 1000;
      display: flex;
      align-items: center;
      justify-content: center;
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
      transition: transform 0.3s ease, box-shadow 0.3s ease;
      pointer-events: auto;
    }
    
    .nav-button:hover {
      transform: scale(1.05);
      box-shadow: 0 6px 20px rgba(0, 0, 0, 0.3);
    }
    
    .nav-button:active {
      transform: scale(0.95);
    }
    
    .arrow-icon {
      width: 40px;
      height: 40px;
      position: relative;
    }
    
    .arrow-icon::before {
      content: '';
      position: absolute;
      width: 20px;
      height: 20px;
      border-top: 3px solid #333;
      border-right: 3px solid #333;
      transform: rotate(45deg);
      top: 50%;
      left: 50%;
      margin-left: -12px;
      margin-top: -10px;
    }
  </style>
</head>
<body>
  <div class="grid js-grid">
    <div><figure class="js-plane" data-src="https://assets.codepen.io/58281/lama-3.jpg?width=1100&format=auto"></figure></div>
    <div><figure class="js-plane" data-src="https://assets.codepen.io/58281/lama-2.jpg?width=1100&format=auto"></figure></div>
    <div><figure class="js-plane" data-src="https://assets.codepen.io/58281/lama-1.jpg?width=1100&format=auto"></figure></div>
    <div><figure class="js-plane" data-src="https://assets.codepen.io/58281/lama-3.jpg?width=1100&format=auto"></figure></div>
    <div><figure class="js-plane" data-src="https://assets.codepen.io/58281/lama-2.jpg?width=1100&format=auto"></figure></div>
    <div><figure class="js-plane" data-src="https://assets.codepen.io/58281/lama-1.jpg?width=1100&format=auto"></figure></div>
    <div><figure class="js-plane" data-src="https://assets.codepen.io/58281/lama-3.jpg?width=1100&format=auto"></figure></div>
    <div><figure class="js-plane" data-src="https://assets.codepen.io/58281/lama-2.jpg?width=1100&format=auto"></figure></div>
    <div><figure class="js-plane" data-src="https://assets.codepen.io/58281/lama-1.jpg?width=1100&format=auto"></figure></div>
    <div><figure class="js-plane" data-src="https://assets.codepen.io/58281/lama-3.jpg?width=1100&format=auto"></figure></div>
    <div><figure class="js-plane" data-src="https://assets.codepen.io/58281/lama-2.jpg?width=1100&format=auto"></figure></div>
    <div><figure class="js-plane" data-src="https://assets.codepen.io/58281/lama-1.jpg?width=1100&format=auto"></figure></div>
    <div><figure class="js-plane" data-src="https://assets.codepen.io/58281/lama-1.jpg?width=1100&format=auto"></figure></div>
    <div><figure class="js-plane" data-src="https://assets.codepen.io/58281/lama-3.jpg?width=1100&format=auto"></figure></div>
    <div><figure class="js-plane" data-src="https://assets.codepen.io/58281/lama-2.jpg?width=1100&format=auto"></figure></div>
  </div>
  
  <!-- Navigation Button -->
  <button class="nav-button" onclick="navigateToCanvas()">
    <div class="arrow-icon"></div>
  </button>
  
  <script>
    function navigateToCanvas() {
      window.parent.postMessage('navigate_to_canvas', '*');
    }
    
    console.clear();
    
    let ww = window.innerWidth;
    let wh = window.innerHeight;
    
    const isFirefox = navigator.userAgent.indexOf('Firefox') > -1;
    const isWindows = navigator.appVersion.indexOf("Win") != -1;
    
    const mouseMultiplier = 0.6;
    const firefoxMultiplier = 20;
    
    const multipliers = {
      mouse: isWindows ? mouseMultiplier * 2 : mouseMultiplier,
      firefox: isWindows ? firefoxMultiplier * 2 : firefoxMultiplier
    };
    
    class Core {
      constructor() {
        this.tx = 0;
        this.ty = 0;
        this.cx = 0;
        this.cy = 0;
        this.diff = 0;
        this.wheel = { x: 0, y: 0 };
        this.on = { x: 0, y: 0 };
        this.max = { x: 0, y: 0 };
        this.isDragging = false;
        this.tl = gsap.timeline({ paused: true });
        this.el = document.querySelector('.js-grid');
        
        this.scene = new THREE.Scene();
        this.camera = new THREE.OrthographicCamera(
          ww / -2, ww / 2, wh / 2, wh / -2, 1, 1000
        );
        this.camera.lookAt(this.scene.position);
        this.camera.position.z = 1;
        
        this.renderer = new THREE.WebGLRenderer({ antialias: true });
        this.renderer.setSize(ww, wh);
        this.renderer.setPixelRatio(
          gsap.utils.clamp(1, 1.5, window.devicePixelRatio)
        );
        
        document.body.appendChild(this.renderer.domElement);
        
        this.addPlanes();
        this.addEvents();
        this.resize();
      }
      
      addEvents() {
        gsap.ticker.add(this.tick);
        window.addEventListener('mousemove', this.onMouseMove);
        window.addEventListener('mousedown', this.onMouseDown);
        window.addEventListener('mouseup', this.onMouseUp);
        window.addEventListener('wheel', this.onWheel);
      }
      
      addPlanes() {
        const planes = [...document.querySelectorAll('.js-plane')];
        this.planes = planes.map((el, i) => {
          const plane = new Plane();
          plane.init(el, i);
          this.scene.add(plane);
          return plane;
        });
      }
      
      tick = () => {
        const xDiff = this.tx - this.cx;
        const yDiff = this.ty - this.cy;
        
        this.cx += xDiff * 0.085;
        this.cx = Math.round(this.cx * 100) / 100;
        
        this.cy += yDiff * 0.085;
        this.cy = Math.round(this.cy * 100) / 100;
        
        this.diff = Math.max(
          Math.abs(yDiff * 0.0001), 
          Math.abs(xDiff * 0.0001)
        );
        
        this.planes.length && this.planes.forEach(plane => 
          plane.update(this.cx, this.cy, this.max, this.diff)
        );
        
        this.renderer.render(this.scene, this.camera);
      }
      
      onMouseMove = (event) => {
        if (!this.isDragging) return;
        this.tx = this.on.x + event.clientX * 2.5;
        this.ty = this.on.y - event.clientY * 2.5;
      }
      
      onMouseDown = (event) => {
        if (this.isDragging) return;
        this.isDragging = true;
        this.on.x = this.tx - event.clientX * 2.5;
        this.on.y = this.ty + event.clientY * 2.5;
      }
      
      onMouseUp = () => {
        if (!this.isDragging) return;
        this.isDragging = false;
      }
      
      onWheel = (e) => {
        const mouse = multipliers.mouse;
        const firefox = multipliers.firefox;
        
        this.wheel.x = e.wheelDeltaX || e.deltaX * -1;
        this.wheel.y = e.wheelDeltaY || e.deltaY * -1;
        
        if (isFirefox && e.deltaMode === 1) {
          this.wheel.x *= firefox;
          this.wheel.y *= firefox;
        }
        
        this.wheel.y *= mouse;
        this.wheel.x *= mouse;
        
        this.tx += this.wheel.x;
        this.ty -= this.wheel.y;
      }
      
      resize = () => {
        ww = window.innerWidth;
        wh = window.innerHeight;
        const rect = this.el.getBoundingClientRect();
        this.max.x = rect.right;
        this.max.y = rect.bottom;
      }
    }
    
    const loader = new THREE.TextureLoader();
    
    const vertexShader = \`
      precision mediump float;
      uniform float u_diff;
      varying vec2 vUv;
      
      void main() {
        vec3 pos = position;
        pos.y *= 1.0 - u_diff;
        pos.x *= 1.0 - u_diff;
        vUv = uv;
        gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
      }
    \`;
    
    const fragmentShader = \`
      precision mediump float;
      uniform vec2 u_res;
      uniform vec2 u_size;
      uniform sampler2D u_texture;
      
      vec2 cover(vec2 screenSize, vec2 imageSize, vec2 uv) {
        float screenRatio = screenSize.x / screenSize.y;
        float imageRatio = imageSize.x / imageSize.y;
        
        vec2 newSize = screenRatio < imageRatio 
          ? vec2(imageSize.x * (screenSize.y / imageSize.y), screenSize.y)
          : vec2(screenSize.x, imageSize.y * (screenSize.x / imageSize.x));
          
        vec2 newOffset = (screenRatio < imageRatio 
          ? vec2((newSize.x - screenSize.x) / 2.0, 0.0) 
          : vec2(0.0, (newSize.y - screenSize.y) / 2.0)) / newSize;
        
        return uv * screenSize / newSize + newOffset;
      }
      
      varying vec2 vUv;
      
      void main() {
        vec2 uv = vUv;
        vec2 uvCover = cover(u_res, u_size, uv);
        vec4 texture = texture2D(u_texture, uvCover);
        gl_FragColor = texture;
      }
    \`;
    
    const geometry = new THREE.PlaneBufferGeometry(1, 1, 1, 1);
    const material = new THREE.ShaderMaterial({
      fragmentShader: fragmentShader,
      vertexShader: vertexShader
    });
    
    class Plane extends THREE.Object3D {
      init(el, i) {
        this.el = el;
        this.x = 0;
        this.y = 0;
        this.my = 1 - ((i % 5) * 0.1);
        
        this.geometry = geometry;
        this.material = material.clone();
        
        this.material.uniforms = {
          u_texture: { value: 0 },
          u_res: { value: new THREE.Vector2(1, 1) },
          u_size: { value: new THREE.Vector2(1, 1) },
          u_diff: { value: 0 }
        };
        
        this.texture = loader.load(this.el.dataset.src, (texture) => {
          texture.minFilter = THREE.LinearFilter;
          texture.generateMipmaps = false;
          
          const naturalWidth = texture.image.naturalWidth;
          const naturalHeight = texture.image.naturalHeight;
          
          this.material.uniforms.u_texture.value = texture;
          this.material.uniforms.u_size.value.x = naturalWidth;
          this.material.uniforms.u_size.value.y = naturalHeight;
        });
        
        this.mesh = new THREE.Mesh(this.geometry, this.material);
        this.add(this.mesh);
        this.resize();
      }
      
      update = (x, y, max, diff) => {
        const rect = this.rect;
        const right = rect.right;
        const bottom = rect.bottom;
        
        this.y = gsap.utils.wrap(
          -(max.y - bottom),
          bottom,
          y * this.my
        ) - this.yOffset;
        
        this.x = gsap.utils.wrap(
          -(max.x - right),
          right,
          x
        ) - this.xOffset;
        
        this.material.uniforms.u_diff.value = diff;
        
        this.position.x = this.x;
        this.position.y = this.y;
      }
      
      resize() {
        this.rect = this.el.getBoundingClientRect();
        
        const left = this.rect.left;
        const top = this.rect.top;
        const width = this.rect.width;
        const height = this.rect.height;
        
        this.xOffset = (left + (width / 2)) - (ww / 2);
        this.yOffset = (top + (height / 2)) - (wh / 2);
        
        this.position.x = this.xOffset;
        this.position.y = this.yOffset;
        
        this.material.uniforms.u_res.value.x = width;
        this.material.uniforms.u_res.value.y = height;
        
        this.mesh.scale.set(width, height, 1);
      }
    }
    
    new Core();
  </script>
</body>
</html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: HtmlElementView(viewType: viewId),
    );
  }
}