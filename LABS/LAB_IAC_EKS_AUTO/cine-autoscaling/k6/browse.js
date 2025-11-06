import http from "k6/http";
import { sleep, check } from "k6";

export const options = {
  stages: [
    { duration: "1m", target: 20 },
    { duration: "3m", target: 40 },
    { duration: "2m", target: 0 },
  ],
};

const ALB = __ENV.ALB;

export default function () {
  const res1 = http.get(`http://${ALB}/`);
  check(res1, { "status 200 catálogo": (r) => r.status === 200 });

  // visita películas al azar
  for (let i = 1; i <= 10; i++) {
    const r = http.get(`http://${ALB}/movie/${Math.ceil(Math.random() * 5)}`);
    check(r, { "status 200 detalle": (r) => r.status === 200 });
    sleep(1);
  }
}
